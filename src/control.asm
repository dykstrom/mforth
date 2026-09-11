; Control flow: the two words that move IP, and the words that compile them.
;
; Up to here IP has only ever gone forward, a cell at a time in NEXT and one
; more in LIT. BRANCH and 0BRANCH are what put it somewhere else, and every
; conditional and loop in Forth is built out of those two.
;
; The point worth saying aloud is that IF, ELSE, THEN and the rest are not
; syntax. They are ordinary words, marked immediate so that they run while the
; compiler is compiling, and each one does nothing but append a cell or store
; into a cell appended earlier. The compiler needs no case for any of them.

        section .text

; BRANCH ( -- ) jumps to the address stored in the cell after it.
;
; NEXT has already stepped IP past BRANCH's own token, so IP points at that
; cell, and loading it is the whole word.
;
; The cell holds an absolute address, not an offset. That makes the jump one
; instruction and patching one store with no arithmetic: THEN writes HERE into
; the cell and is finished. jonesforth stores a relative offset instead, which
; would let a compiled definition be moved in memory. mforth never moves one.
; See docs/adr/0008-branch-targets-are-absolute-addresses.md.
        defcode "BRANCH", branch
        mov     IP, [IP]                ; the cell after BRANCH is the target
        NEXT

; 0BRANCH ( flag -- ) jumps to the address stored in the cell after it when
; flag is 0, and carries on past that cell when it is not.
;
; This is the conditional, and it is the only one: IF, UNTIL and WHILE all
; compile this same word. Jumping when the flag is false rather than true is
; what makes IF read forwards - IF compiles a jump over the code it guards, so
; a false flag skips it.
        defcode "0BRANCH", zero_branch
        mov     rax, [DSP]              ; the flag
        add     DSP, 8                  ; drop it
        test    rax, rax
        jz      .take_the_branch
        add     IP, 8                   ; step over the target and carry on
        NEXT
.take_the_branch:
        mov     IP, [IP]
        NEXT

; The words below compile the two above. Two kinds of address travel on the
; data stack between them, and telling them apart is the whole trick:
;
;   a hole     the address of a placeholder cell that a later word overwrites
;              with HERE. IF, ELSE and WHILE leave one.
;   a target   an address already known, to be compiled as something to jump
;              back to. BEGIN and DO leave one.
;
; Nothing checks which kind it has been handed, or that it has been handed
; anything at all. A stray THEN stores a cell at whatever address was on the
; data stack, and IF ... UNTIL compiles without complaint. That is the answer
; the two stacks, the dictionary region and @ all already give.

; IF ( -- hole ) compiles a jump over the code it guards. Immediate.
;
; The target of that jump is not known yet: it is wherever THEN turns out to
; be. So IF compiles a placeholder and leaves its address for THEN to fill in.
        defcode "IF", if, F_IMMEDIATE
        mov     rdi, xt_zero_branch
        call    comma_cell
        mov     rax, [here]             ; where the placeholder is about to go
        sub     DSP, 8
        mov     [DSP], rax              ; leave the hole for THEN or ELSE
        xor     edi, edi
        call    comma_cell              ; the placeholder itself
        NEXT

; ELSE ( hole1 -- hole2 ) ends the true part and begins the false one.
; Immediate.
;
; Two things have to happen here. The true part, having run, must jump over the
; false part, so ELSE compiles a BRANCH with a placeholder of its own. And IF's
; jump must land here, after that BRANCH, so ELSE fills IF's hole with HERE.
        defcode "ELSE", else, F_IMMEDIATE
        mov     rdi, xt_branch
        call    comma_cell
        mov     rax, [here]             ; where ELSE's own placeholder goes
        mov     rcx, [DSP]              ; hole1, the one IF left
        mov     [DSP], rax              ; hole2 replaces it for THEN
        lea     rdx, [rax + 8]          ; the false part starts after the hole
        mov     [rcx], rdx              ; IF's jump lands there
        xor     edi, edi
        call    comma_cell              ; ELSE's placeholder
        NEXT

; THEN ( hole -- ) marks where the jump before it lands. Immediate.
;
; It compiles nothing. All it does is store the address it is standing at into
; the hole that IF or ELSE left, which is why a conditional costs no run-time
; work beyond the one 0BRANCH.
        defcode "THEN", then, F_IMMEDIATE
        mov     rcx, [DSP]              ; the hole
        add     DSP, 8
        mov     rax, [here]             ; where we are now
        mov     [rcx], rax
        NEXT

; BEGIN ( -- target ) marks the top of a loop. Immediate.
;
; Nothing is compiled and nothing is patched later: the address is already
; known, because it is where the next word compiled will go. UNTIL and REPEAT
; are the words that use it.
        defcode "BEGIN", begin, F_IMMEDIATE
        mov     rax, [here]
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; UNTIL ( target -- ) loops back to BEGIN while the flag is false. Immediate.
;
; 0BRANCH jumps when the flag is 0, so the loop runs again until the body
; leaves a true flag. The body of the loop therefore runs at least once.
        defcode "UNTIL", until, F_IMMEDIATE
        mov     rdi, xt_zero_branch
        call    comma_cell
        mov     rdi, [DSP]              ; the target BEGIN left
        add     DSP, 8
        call    comma_cell
        NEXT

; WHILE ( target -- target hole ) leaves the loop when the flag is false.
; Immediate.
;
; The test is in the middle of the body rather than at the end, so this is the
; loop that can run its body no times at all. WHILE compiles the 0BRANCH that
; leaves and a placeholder for where leaving lands, which REPEAT fills in. The
; hole goes above BEGIN's target, because REPEAT needs both and takes them in
; that order.
        defcode "WHILE", while, F_IMMEDIATE
        mov     rdi, xt_zero_branch
        call    comma_cell
        mov     rax, [here]             ; where the placeholder goes
        sub     DSP, 8
        mov     [DSP], rax              ; the hole, on top of the target
        xor     edi, edi
        call    comma_cell
        NEXT

; REPEAT ( target hole -- ) ends a BEGIN WHILE loop. Immediate.
;
; It compiles the jump back to BEGIN, and only then fills WHILE's hole with
; HERE, so that leaving the loop lands after that jump.
; Both addresses have to outlive the two calls, and comma_cell touches nothing
; but rax and rdi, so r8 and r9 hold them.
        defcode "REPEAT", repeat, F_IMMEDIATE
        mov     r8, [DSP]               ; the hole WHILE left, on top
        mov     r9, [DSP + 8]           ; the target BEGIN left, under it
        add     DSP, 16
        mov     rdi, xt_branch
        call    comma_cell
        mov     rdi, r9
        call    comma_cell              ; jump back to BEGIN
        mov     rax, [here]
        mov     [r8], rax               ; WHILE's jump lands after that jump
        NEXT

; The three words below are the counted loop. DO and LOOP are immediate and
; compile the two that follow them; (DO) and (LOOP) are the halves that run.
; The parentheses are Forth's own way of naming the run-time half of a
; compiling word, and both are findable words like any other.
;
; The limit and the index live on the return stack, as they do in every Forth,
; and that stack already holds the address docol saved and anything >R parked
; there. Three things follow, and nothing reports any of them:
;
;   I inside a word called from a loop body reads that word's docol-saved IP
;   and not the index, because the call put a cell on top of the index.
;
;   EXIT inside an unfinished loop returns to a loop parameter and not to the
;   caller.
;
;   R@ and R> in a loop body reach the index, not whatever the return stack
;   held before the loop started. >R followed by R@ still works, because the
;   parked cell goes on top of the index; what breaks is a >R still unbalanced
;   when (LOOP) runs, because (LOOP) then reads the parked cell as the index.
;   This is why a Forth programmer keeps >R and R> in the same breath.

; (DO) ( limit start -- ) ( R: -- limit index ) starts a counted loop.
;
; The index goes on top, because I and (LOOP) read it far more often than they
; read the limit.
        defcode "(DO)", do_runtime
        mov     rax, [DSP]              ; start, which becomes the index
        mov     rcx, [DSP + 8]          ; limit
        add     DSP, 16
        sub     RSP, 8
        mov     [RSP], rcx              ; the limit, underneath
        sub     RSP, 8
        mov     [RSP], rax              ; the index, on top
        NEXT

; (LOOP) ( -- ) ( R: limit index -- limit index | ) ends one turn of the loop.
;
; It adds one to the index and goes back to the address in the cell after it
; unless the index has reached the limit, in which case it drops both
; parameters and carries on past that cell.
;
; The test is for equality, which is what Forth 2012 says. A loop whose limit
; is not above its start therefore does not run no times: 0 0 DO LOOP counts
; all the way round through every 64-bit value before the index meets 0 again.
; The standard has ?DO for that case, and mforth does not.
        defcode "(LOOP)", loop_runtime
        mov     rax, [RSP]              ; the index
        inc     rax
        mov     [RSP], rax
        cmp     rax, [RSP + 8]          ; against the limit
        jne     .go_round_again
        add     RSP, 16                 ; the loop is done with both parameters
        add     IP, 8                   ; step over the target
        NEXT
.go_round_again:
        mov     IP, [IP]
        NEXT

; I ( -- n ) leaves the index of the innermost counted loop.
;
; The index is the top of the return stack, put there by (DO). Read the note
; above for what happens when something else has been put on top of it since.
        defcode "I", i
        mov     rax, [RSP]
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; DO ( -- target ) begins a counted loop. Immediate.
;
; It compiles the run-time half and leaves the address after it, which is where
; each turn of the loop begins and so what LOOP compiles as its target.
        defcode "DO", do, F_IMMEDIATE
        mov     rdi, xt_do_runtime
        call    comma_cell
        mov     rax, [here]
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; LOOP ( target -- ) ends a counted loop. Immediate.
        defcode "LOOP", loop, F_IMMEDIATE
        mov     rdi, xt_loop_runtime
        call    comma_cell
        mov     rdi, [DSP]              ; the target DO left
        add     DSP, 8
        call    comma_cell
        NEXT
