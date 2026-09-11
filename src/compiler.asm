; The compiler: the words that add to the dictionary while mforth runs.
;
; Every word up to here was laid down by the header macro before the program
; started. This file is what lets a person define one from the keyboard. HERE
; says where the next free byte is, ALLOT reserves bytes, the comma words store
; a cell or a byte, and CREATE lays down a header. ":" starts a definition and
; ";" ends it.
;
; The three subroutines at the top are called the way find_name is: plain
; assembly, arguments in the registers the C library would use. Each Forth word
; below them is a wrapper that moves cells between the data stack and those
; registers, which is the same split FIND and find_name already use.

        section .bss

; Where a word defined at runtime goes: its header first and its body after,
; and the next word defined after that. Nothing checks this region for
; overflow, the same answer the two stacks give.
dictionary_space:
        resb    DICTIONARY_SIZE

        section .data

; The next free byte of that region. HERE leaves this value, and everything
; that lays something down moves it on.
here:
        dq      dictionary_space

; What the interpreter is doing: 0 while it runs the words it reads, -1 while
; it compiles them into a definition. INTERPRET reads this cell for every word
; it handles, and ":" and ";" are what write it.
;
; -1 rather than 1, because -1 is the true that the comparison words leave.
state:
        dq      0

; The newest word in the dictionary, and so where every walk starts. FIND
; follows the links back from here, and create_header writes it each time a
; word is defined.
;
; main stores the last header the assembler laid down into this cell at
; startup. That cannot be done here, because at this line the assembler has
; only reached the compiler's own words and the ones before it: the interpreter
; in src/outer.asm is not defined yet, and a walk starting here would never
; reach it.
latest:
        dq      0

        section .text

; header_flags works out where a header's flags cell is.
;
; A name is as long as it is, so the flags are not a fixed distance from the
; front of a header: the length byte and the characters have to be stepped over
; and the answer rounded up to the next cell.
;
; There are two ways through a header, and which one code takes depends on what
; it is holding. Code holding an execution token reads the flags at [xt - 8],
; one instruction, and that is what ADR 0004 put the flags before the code
; field to buy: INTERPRET tests F_IMMEDIATE that way for every word it
; compiles. Code holding a header has to count forward instead, and that is the
; cost the same ADR accepted. This subroutine is where the cost is paid, so it
; is paid once: create_header is laying a header down and has no code field to
; step back from, find_name is part-way along the chain, and ";" runs after the
; body has moved HERE past the code field.
;
; ":" is the one caller that could step back, because create_header leaves HERE
; at the code field. It calls this instead so that it reads like ";".
;
;   in    rdi   the address of a header
;   out   rax   the address of that header's flags cell
;
; It calls nothing and touches nothing but rax. That is what lets find_name
; call it in the middle of a walk holding live values in r14, r15 and rbp.
header_flags:
        movzx   rax, byte [rdi + 8]     ; how long the name is
        lea     rax, [rdi + rax + 9]    ; one past the last character
        add     rax, 7
        and     rax, -8                 ; round up: the flags cell starts here
        ret

        section .text

; comma_cell stores one cell at HERE and steps HERE past it.
;
; This is the whole of what the word "," does. ":", ";" and the compiling half
; of INTERPRET all need the same three lines, which is why it is a subroutine
; and not just the body of the word.
;
;   in    rdi   the cell to store
;   out   none  the cell sits at the old HERE, and HERE has moved on eight
;
; It touches rax and rdi only. INTERPRET relies on that when it compiles a
; number: it keeps the value it is about to store in r8 across the call.
comma_cell:
        mov     rax, [here]
        mov     [rax], rdi
        add     rax, 8
        mov     [here], rax
        ret

        section .text

; create_header lays down the header of a new word and links it in.
;
; It builds the header the macro builds, in the same order: the link, the
; length byte, the characters, and the flags, with the name padded out to the
; next cell so that the flags and the code field land on a cell boundary.
; include/dictionary.inc draws the layout.
;
;   in    rdi   where the name starts
;         rsi   how many characters that name has
;   out   none  the header is in the dictionary, and HERE is at the code field
;
; The new word becomes the newest in the dictionary, so latest is written here
; and the next word defined links back to this one. The flags are left 0. A
; caller that wants one set writes it afterwards, which is what ":" does.
;
; The padding bytes are not written at all. The region is .bss, so it starts as
; zeros, and nothing ever reads them: FIND compares as many characters as the
; length byte says.
create_header:
        mov     rdx, [here]             ; the front of the new header
        mov     rax, [latest]
        mov     [rdx], rax              ; the word defined before this one
        mov     [latest], rdx           ; and this one is the newest now
        add     rdx, 8
        mov     [rdx], sil              ; the length byte
        inc     rdx
        test    rsi, rsi                ; a name of no characters copies none
        jz      .name_is_done
.next_char:
        mov     al, [rdi]
        mov     [rdx], al
        inc     rdi
        inc     rdx
        dec     rsi
        jnz     .next_char
; The flags cell sits on the next cell boundary after the name, and
; header_flags above is what knows where that is. The header is far enough
; along to ask: the length byte is written, and the length byte is all that
; subroutine reads.
.name_is_done:
        mov     rdi, [here]             ; the front of the header
        call    header_flags
        mov     qword [rax], 0          ; the flags
        add     rax, 8
        mov     [here], rax             ; the code field starts here
        ret

; HERE ( -- addr ) leaves the address of the next free byte of the dictionary.
;
; This leaves the value of the cell, not the address of it: HERE says where the
; free space is, not where the pointer to it lives. STATE below is the other
; way round. That asymmetry is the standard's, not a choice made here.
        defcode "HERE", here_word
        mov     rax, [here]
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; ALLOT ( n -- ) reserves n bytes of the dictionary.
;
; Nothing is written into them, so what ALLOT hands out is whatever was there.
; A negative n moves HERE back and gives the space up again, which the standard
; allows and which costs nothing here because one addition does both.
        defcode "ALLOT", allot
        mov     rax, [DSP]
        add     DSP, 8
        add     [here], rax
        NEXT

; , ( n -- ) stores n at HERE and steps HERE past it.
;
; This is how a cell gets into a definition. The name is a single comma, which
; is a word like any other: the interpreter looks it up the way it looks up
; DUP, because a name is whatever characters stand between two spaces.
        defcode ",", comma
        mov     rdi, [DSP]
        add     DSP, 8
        call    comma_cell
        NEXT

; C, ( c -- ) stores the low byte of c at HERE and steps HERE past it.
;
; HERE moves on by one, so the byte after it is no longer on a cell boundary.
; Nothing here puts it back: a program that mixes C, and , looks after its own
; alignment.
        defcode "C,", c_comma
        mov     rax, [DSP]
        add     DSP, 8
        mov     rdx, [here]
        mov     [rdx], al               ; the low byte of it only
        inc     rdx
        mov     [here], rdx
        NEXT

; STATE ( -- addr ) leaves the address of the cell that says what the
; interpreter is doing.
;
; The cell holds 0 while mforth runs the words it reads and -1 while it
; compiles them. STATE leaves the address and not the value, so STATE @ is how
; a program reads it, and @ from src/words.asm does the work. That is the
; standard's shape, and it is the opposite way round from HERE above.
        defcode "STATE", state_word
        mov     rax, state
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; CREATE ( c-addr u -- ) lays down the header of a word of that name.
;
; What follows the header is the caller's business. CREATE stops with HERE at
; the code field and writes nothing into it, so the new word cannot be run
; until something does. ":" below writes docol there.
;
; The standard's CREATE parses its own name out of the input and writes a code
; field that pushes the address of the word's body. mforth's takes the name off
; the stack, the way FIND does, and lays the header and nothing else. WORD
; CREATE is then the standard's spelling of it, and ":" needs no more than
; this. See docs/adr/0007-create-takes-its-name-from-the-stack.md.
        defcode "CREATE", create
        mov     rdi, [DSP + 8]          ; where the name starts
        mov     rsi, [DSP]              ; how many characters it has
        add     DSP, 16                 ; both items are gone
        call    create_header
        NEXT

; : ( -- ) starts a definition.
;
; It takes the next word of the line as the name, lays a header down under it,
; writes docol into the code field, and puts the interpreter into compiling.
; Every word up to the ";" is then appended to the body instead of being run.
;
; The new word is hidden while it is being defined. A name that already exists
; therefore still means the older word until ";" clears the flag, which is what
; lets ": FOO FOO 1 + ;" define a FOO out of the FOO before it.
;
; Nothing checks that the line holds a name, or that a definition is not
; already open. ": ;" on its own defines a word with no name, which no name can
; then reach.
;
; This is what ": PRINT42 42 . CR ;" leaves behind. The header is the same one
; a word written in assembly has. What differs is the code field: it holds
; docol, and the execution tokens of the words to run follow it.
;
;                     dictionary_space           section .text
;
;   header_print42 -> +------------------+
;                     | link             |   the word defined before PRINT42
;                     | 7 P R I N T 4 2  |   the name: a length, then characters
;                     | flags = 0        |   F_HIDDEN until the ";"
;   xt_print42 ->     | docol            | -------> docol: sub RSP, 8
;                     +------------------+                 mov [RSP], IP
;                     | xt_lit           | -.              lea IP, [W + 8]
;                     |    42            |  |              NEXT
;                     | xt_dot           |  |- the body
;                     | xt_cr            |  |
;                     | xt_exit          | -'
;                     +------------------+
;
; ":" writes the header and the docol; INTERPRET appends the four tokens of the
; body as it reads them, the number through xt_lit; ";" appends the xt_exit.
; The interpreter then reaches PRINT42 by looking its name up, exactly the way
; it reaches DUP: nothing that runs a word has to know which of the two kinds
; it is.
        defcode ":", colon
        call    parse_word              ; rax is where the name starts
        mov     rdi, rax
        mov     rsi, rdx                ; and rdx is how many characters
        call    create_header           ; HERE is at the code field now
        mov     rdi, [latest]           ; the header just laid down
        call    header_flags
        mov     qword [rax], F_HIDDEN   ; no name reaches it until ";"
        mov     rdi, docol
        call    comma_cell              ; the code field: enter a Forth word
        mov     qword [state], -1       ; compile what comes next
        NEXT

; ; ( -- ) ends a definition. It is immediate, so it runs while the interpreter
; is compiling rather than being compiled.
;
; This is the word that has to be immediate. Every other word on the line went
; into the body, and if this one did too then nothing would ever end the
; definition. The flag is set on the defcode line above, and INTERPRET reads it
; at [xt - 8].
;
; EXIT is compiled last, so the finished word returns to whatever ran it. The
; hidden flag is cleared after that, because the name should not be findable
; until the body behind it is complete.
        defcode ";", semicolon, F_IMMEDIATE
        mov     rdi, xt_exit
        call    comma_cell              ; the body ends by returning
        mov     rdi, [latest]
        call    header_flags
        mov     qword [rax], 0          ; findable from now on
        mov     qword [state], 0        ; back to running what is read
        NEXT

; IMMEDIATE ( -- ) marks the word just defined immediate.
;
; It is typed after ";" rather than given to ":", because ";" clears the whole
; flags cell to drop F_HIDDEN and would clear this with it. That is why Forth
; writes "; IMMEDIATE" and not ": IMMEDIATE FOO".
;
; This word is what lets lib/prelude.f define IF, ELSE and THEN, which have to
; run while the compiler is compiling. Without this word the only way to set
; the flag is the third argument of defcode, which an assembly word can use and
; a word a person defines cannot.
        defcode "IMMEDIATE", immediate
        mov     rdi, [latest]
        call    header_flags
        or      qword [rax], F_IMMEDIATE
        NEXT
