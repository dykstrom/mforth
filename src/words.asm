; The words mforth knows by name. Most of them are nothing but assembly: they
; move cells between the two stacks, do arithmetic on them, or read and write
; memory. The few at the end go through libc or through the dictionary.
;
; Every word here is defined with the defcode macro from
; include/dictionary.inc, which lays down the header, the code field, and the
; label the machine code starts at. What this file used to spell out for each
; word is now one line per word:
;
;                   section .data              section .text
;
;   header_cr -> +------------------+
;                | link             |   the word defined before CR
;                | 2 C R 0 0 0 0 0  |   the name: a length, then characters
;                | flags = 0        |
;   xt_cr ->     | code_cr          | -------> code_cr: mov  edi, 10
;                +------------------+                   call putchar
;                                                       NEXT
;
; The order the words appear in is the order they are chained in. LIT comes
; first, so its link is 0 and a walk reaches it last. EXECUTE is the last word
; defined here, but not the last word defined: src/compiler.asm and
; src/outer.asm come after it, which is why `latest`, the cell a walk starts
; from, is set up in main and not here.

        extern  printf                  ; printf(const char *format, ...)
        extern  putchar                 ; putchar(int c)
        extern  exit                    ; exit(int status)
        extern  memcmp                  ; memcmp(const void *, const void *, size_t)

; LIT ( -- n ) pushes the number stored in the thread just after LIT.
;
; A number written in a program has to live somewhere, and in threaded code
; there is nowhere to put it but the thread itself. LIT reads the cell IP
; points at, which is that number rather than a word to run, and steps IP past
; it so that NEXT does not try to execute it.
;
; A Forth normally keeps LIT out of reach, because typing it where there is no
; thread to read from makes no sense. mforth gives it a name like every other
; word, and F_HIDDEN, the flag that would take the name away, is used only by
; ":" for a definition still being built.
;
; This is the word INTERPRET compiles when a number appears inside a
; definition: the token of LIT, and then the number itself in the cell after
; it.
        defcode "LIT", lit
        mov     rax, [IP]               ; the number sitting in the thread
        add     IP, 8                   ; step over it
        sub     DSP, 8                  ; make room on the data stack
        mov     [DSP], rax
        NEXT

; DUP ( n -- n n ) leaves a second copy of the top of the data stack.
        defcode "DUP", dup
        mov     rax, [DSP]
        sub     DSP, 8                  ; make room for the copy
        mov     [DSP], rax
        NEXT

; DROP ( n -- ) throws away the top of the data stack.
;
; Nothing is erased. The pointer moves up one cell, and the next push writes
; over what was there.
        defcode "DROP", drop
        add     DSP, 8
        NEXT

; SWAP ( n1 n2 -- n2 n1 ) exchanges the top two items on the data stack.
        defcode "SWAP", swap
        mov     rax, [DSP]              ; n2, the top item
        mov     rdx, [DSP + 8]          ; n1, the one under it
        mov     [DSP + 8], rax
        mov     [DSP], rdx
        NEXT

; OVER ( n1 n2 -- n1 n2 n1 ) copies the second item to the top.
;
; DUP copies the top item; OVER reaches one cell further down. Between them a
; word can get at either of the two items it was given without losing the
; other, which is why these two are the stack words that have to be assembly.
        defcode "OVER", over
        mov     rax, [DSP + 8]          ; n1, the item under the top
        sub     DSP, 8                  ; make room for the copy
        mov     [DSP], rax
        NEXT

; ROT ( n1 n2 n3 -- n2 n3 n1 ) brings the third item up to the top.
;
; The three move round by one place, and the item that was deepest is the one
; that comes out on top. A word given three arguments uses ROT to reach the
; one it cannot otherwise see.
        defcode "ROT", rot
        mov     rax, [DSP + 16]         ; n1, the third item down
        mov     rcx, [DSP + 8]          ; n2, the second
        mov     rdx, [DSP]              ; n3, the top
        mov     [DSP + 16], rcx
        mov     [DSP + 8], rdx
        mov     [DSP], rax
        NEXT

; DEPTH ( -- n ) leaves how many items were on the data stack before it ran.
;
; The stack grows downward from data_stack_top, so the distance between that
; label and DSP is how much of the stack is in use. The count is worked out
; before the push, so DEPTH on an empty stack leaves 0 rather than 1.
        defcode "DEPTH", depth
        mov     rax, data_stack_top
        sub     rax, DSP                ; how many bytes are in use
        shr     rax, 3                  ; eight bytes to a cell
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; + ( n1 n2 -- n3 ) leaves the sum of the top two items.
        defcode "+", plus
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        add     [DSP], rax              ; and add it to the one underneath
        NEXT

; - ( n1 n2 -- n3 ) leaves n1 minus n2.
;
; The order is the order they were typed: 5 3 - leaves 2, because the item
; underneath is the one being subtracted from.
        defcode "-", minus
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        sub     [DSP], rax              ; take it from the one underneath
        NEXT

; * ( n1 n2 -- n3 ) leaves the product of the top two items.
;
; imul here is the two-operand form, which keeps the low 64 bits of the product
; and throws the high half away. That is the same wrap-around every other
; arithmetic word has, and a Forth cell is 64 bits wide.
        defcode "*", star
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        imul    rax, [DSP]              ; multiply by the one underneath
        mov     [DSP], rax
        NEXT

; /MOD ( n1 n2 -- rem quot ) divides n1 by n2 and leaves both answers.
;
; Division produces two results and Forth has a stack, so the word leaves both
; rather than choosing. The remainder goes under the quotient, which is the
; order that lets a caller DROP the one it does not want.
;
; idiv wants the dividend in rdx:rax, so cqo copies the sign of rax through
; the whole of rdx first. Divide by zero raises SIGFPE and kills the process:
; nothing checks for it, in the same way nothing checks the stacks.
;
; The standard has two divisions, one rounding toward zero and one toward
; negative infinity, and lets /MOD follow either. mforth follows idiv, which
; rounds toward zero: -7 2 /MOD leaves -1 and -3.
        defcode "/MOD", slash_mod
        mov     rcx, [DSP]              ; n2, the divisor
        mov     rax, [DSP + 8]          ; n1, the dividend
        cqo                             ; sign-extend rax through rdx:rax
        idiv    rcx                     ; quotient in rax, remainder in rdx
        mov     [DSP + 8], rdx          ; the remainder goes underneath
        mov     [DSP], rax              ; the quotient on top
        NEXT

; A flag in Forth is a cell like any other. False is 0 and true is -1, which is
; every bit set, so that AND, OR and INVERT work on flags as well as on
; numbers: INVERT turns true into false exactly because -1 flips to 0.
;
; setcc writes a byte holding 1 or 0. Negating that is what turns the 1 into
; the all-bits answer Forth wants, so each of the three words below zeroes a
; register, sets its low byte, and negates the whole of it.

; = ( n1 n2 -- flag ) leaves true when the two items are equal.
        defcode "=", equals
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        xor     ecx, ecx                ; the flag, false so far
        cmp     [DSP], rax              ; n1 against n2
        sete    cl
        neg     rcx                     ; 1 becomes -1, and 0 stays 0
        mov     [DSP], rcx
        NEXT

; < ( n1 n2 -- flag ) leaves true when n1 is less than n2.
;
; setl is the signed comparison. mforth has no unsigned words, so every number
; on the stack is a signed 64-bit cell.
        defcode "<", less_than
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        xor     ecx, ecx
        cmp     [DSP], rax              ; n1 against n2
        setl    cl
        neg     rcx
        mov     [DSP], rcx
        NEXT

; > ( n1 n2 -- flag ) leaves true when n1 is greater than n2.
        defcode ">", greater_than
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        xor     ecx, ecx
        cmp     [DSP], rax              ; n1 against n2
        setg    cl
        neg     rcx
        mov     [DSP], rcx
        NEXT

; AND ( n1 n2 -- n3 ) leaves the bitwise and of the top two items.
;
; This is the bitwise operation, not a logical one. On flags it is the logical
; one as well, because true is every bit set and false is none of them.
        defcode "AND", and
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        and     [DSP], rax              ; and it into the one underneath
        NEXT

; OR ( n1 n2 -- n3 ) leaves the bitwise or of the top two items.
        defcode "OR", or
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        or      [DSP], rax
        NEXT

; XOR ( n1 n2 -- n3 ) leaves the bitwise exclusive or of the top two items.
        defcode "XOR", xor
        mov     rax, [DSP]              ; n2, the top item
        add     DSP, 8                  ; drop it
        xor     [DSP], rax
        NEXT

; INVERT ( n1 -- n2 ) flips every bit of the top item.
;
; This is the bitwise complement and not the arithmetic negation: INVERT of 1
; is -2, not -1. NEGATE is the word that changes the sign, and lib/prelude.f
; writes it in Forth as "0 SWAP -".
        defcode "INVERT", invert
        not     qword [DSP]
        NEXT

; The three words below move cells between the two stacks. They are the only
; words a programmer types that touch the return stack, and the reason to want
; them is that the data stack has no way to reach past its top few items: a
; value pushed out of the way on the return stack comes back untouched.
;
; The return stack is also where docol left the address a word returns to, and
; EXIT reads whatever is on top. A definition that pushes onto it and does not
; take the same number of cells back off before EXIT returns to the wrong
; place. Nothing checks for that.

; >R ( n -- ) ( R: -- n ) moves the top of the data stack to the return stack.
        defcode ">R", to_r
        mov     rax, [DSP]
        add     DSP, 8                  ; gone from the data stack
        sub     RSP, 8                  ; and on to the return stack
        mov     [RSP], rax
        NEXT

; R> ( -- n ) ( R: n -- ) moves the top of the return stack back.
        defcode "R>", r_from
        mov     rax, [RSP]
        add     RSP, 8
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; R@ ( -- n ) ( R: n -- n ) copies the top of the return stack without
; taking it off.
;
; This is to the return stack what DUP is to the data stack, and it is how a
; word reads the value it pushed with >R while it is still parked there.
        defcode "R@", r_fetch
        mov     rax, [RSP]
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; The four words below are how Forth reaches memory. An address is a number
; like any other, so it travels on the data stack, and these words are the
; only ones that follow it. A cell is eight bytes; @ and ! move a whole one,
; C@ and C! move a single byte.
;
; Nothing checks that an address is one mforth may touch. @ on a number that
; is not an address reads whatever is there or kills the process.

; @ ( addr -- n ) leaves the cell stored at addr.
        defcode "@", fetch
        mov     rax, [DSP]              ; the address
        mov     rax, [rax]              ; the cell it points at
        mov     [DSP], rax              ; which replaces it on the stack
        NEXT

; ! ( n addr -- ) stores n in the cell at addr.
;
; The address is on top and the value under it, which is the order the two are
; typed: 42 x ! puts 42 in x.
        defcode "!", store
        mov     rax, [DSP]              ; addr, the top item
        mov     rcx, [DSP + 8]          ; n, the value under it
        mov     [rax], rcx
        add     DSP, 16                 ; both items are gone
        NEXT

; C@ ( addr -- c ) leaves the byte stored at addr.
;
; movzx fills the rest of the cell with zeros, so a byte read back is never
; negative. This is the word that reads a character out of a name or a line
; of input.
        defcode "C@", c_fetch
        mov     rax, [DSP]              ; the address
        movzx   rax, byte [rax]         ; one byte, widened to a cell
        mov     [DSP], rax
        NEXT

; C! ( c addr -- ) stores the low byte of c at addr.
;
; The seven bytes above it are left alone. A c larger than a byte loses its
; top, and nothing reports that.
        defcode "C!", c_store
        mov     rax, [DSP]              ; addr, the top item
        mov     rcx, [DSP + 8]          ; c, the value under it
        mov     [rax], cl               ; the low byte of it only
        add     DSP, 16                 ; both items are gone
        NEXT

; . ( n -- ) prints the top of the data stack, followed by one space.
;
; Forth's . leaves the space so that several numbers printed in a row can be
; told apart. printf does the work of turning a 64-bit number into digits;
; %ld is C's long, which on Linux/x86_64 is 64 bits wide.
        defcode ".", dot
        mov     rsi, [DSP]              ; the number to print
        add     DSP, 8                  ; drop it from the data stack
        mov     rdi, dot_format
        xor     eax, eax                ; printf is variadic: no vector args
        call    printf
        NEXT

; CR ( -- ) ends the line of output.
        defcode "CR", cr
        mov     edi, 10                 ; the ASCII line feed
        call    putchar
        NEXT

; BYE ( -- ) leaves mforth.
;
; exit is libc's, not the kernel's: it flushes what printf has buffered before
; the process ends. It never returns, so this is the one word that does not end
; with NEXT.
        defcode "BYE", bye
        xor     edi, edi                ; exit status 0: nothing went wrong
        call    exit

; FIND ( c-addr u -- xt ) looks a name up and leaves its execution token, or 0
; when no word has that name.
;
; c-addr u is how Forth writes a string on the stack: the address of the first
; character, then how many characters there are.
;
; The walk itself is find_name below. The outer interpreter looks a name up for
; every word a person types, and calls that subroutine directly rather than
; going through the Forth machine to reach it.
;
; The standard's FIND leaves a flag beside the execution token, saying whether
; the word is immediate. mforth leaves the token by itself, because the flags
; of a word are always the cell in front of its code field.
        defcode "FIND", find
        mov     rdi, [DSP + 8]          ; where the name starts
        mov     rsi, [DSP]              ; how many characters it has
        call    find_name
        add     DSP, 8                  ; drop the length
        mov     [DSP], rax              ; the answer goes where c-addr was
        NEXT

; find_name walks the dictionary from the newest word backwards, comparing the
; name it was given with each word's own. It takes the address of the name in
; rdi and its length in rsi, and leaves the execution token in rax, or 0 when
; no word carries that name.
;
; A word whose flags carry F_HIDDEN is passed over as though its name did not
; match, so a definition under construction cannot be found by its own name.
;
; This is an ordinary assembly subroutine called the way libc's are, not a
; Forth word. FIND above and the outer interpreter both use it. It takes its
; arguments where the C library would, so the registers below are the first two
; of the System V ABI and its return register.
;
;   in    rdi   where the name to look up starts
;         rsi   how many characters that name has
;   out   rax   the execution token, or 0 when no word has that name
;
; The walk carries three values across the call to memcmp: the header being
; looked at, the name being looked for, and how long that name is. They live in
; r14, r15 and rbp because the System V ABI counts all three as callee-saved,
; so memcmp gives them back untouched. Nothing else in mforth holds a value in
; any of the three.
;
; The push is what keeps the machine stack aligned. main left rsp on a 16-byte
; boundary, and the call that reached this subroutine pushed a return address
; onto it. Pushing one more cell puts the boundary back, so memcmp is entered
; the way the ABI says. refill in src/outer.asm pushes rbp before it calls
; getchar for the same two reasons.
find_name:
        push    rbp
        mov     r15, rdi                ; the name has to outlive memcmp
        mov     rbp, rsi                ; and so does its length
        mov     r14, [latest]           ; the newest word in the dictionary
.this_word:
        test    r14, r14                ; 0 is the link of the first word
        jz      .no_such_word
        movzx   rax, byte [r14 + 8]     ; how long this word's name is
        cmp     rax, rbp                ; how long the wanted name is
        jne     .word_before            ; two lengths that differ cannot match
        mov     rdi, r15                ; the name we are looking for
        lea     rsi, [r14 + 9]          ; this word's name, after its length
        mov     rdx, rbp                ; compare that many characters
        call    memcmp                  ; 0 when the two are the same
        test    eax, eax
        jz      .found
.word_before:
        mov     r14, [r14]              ; the word defined before this one
        jmp     .this_word

; The name matches. A word marked hidden is passed over even so, and the walk
; carries on to the word defined before it: that is what makes the name inside
; ": FOO FOO 1 + ;" mean the FOO that already existed.
;
; The code field follows the header, and the execution token is its address.
; Walking there means stepping over the length byte and the name, over the
; padding that rounds the name up to a cell, and over the flags.
.found:
        mov     rdi, r14                ; the header the walk stopped at
        call    header_flags
        test    qword [rax], F_HIDDEN
        jnz     .word_before
        add     rax, 8                  ; step over the flags to the code field
        pop     rbp
        ret

.no_such_word:
        xor     eax, eax                ; the walk ran off the end of the chain
        pop     rbp
        ret

; EXECUTE ( xt -- ) runs the word whose execution token is on the data stack.
;
; This is the last instruction of NEXT, with the token taken from the stack
; instead of from the thread. Nothing else is needed: the word that runs ends
; with its own NEXT, which carries on from where IP points already.
        defcode "EXECUTE", execute
        mov     W, [DSP]                ; the execution token to run
        add     DSP, 8
        jmp     [W]                     ; jump through its code field

        section .rodata

; printf wants its format as a NUL-terminated string. The space . leaves after
; the number is part of the format, so printing a number takes one call.
dot_format:
        db      "%ld ", 0
