; The words mforth knows by name. LIT, the three stack words and the two
; arithmetic words are nothing but assembly; the rest go through libc or
; through the dictionary.
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
; defined here, but not the last word defined: PRINT42 in src/mforth.asm comes
; after it, which is why `latest`, the cell a walk starts from, is written
; there rather than here.

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
; word; the flag that hides a word arrives with ticket 006.
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

; The code field follows the header, and the execution token is its address.
; Walking there means stepping over the length byte and the name, over the
; padding that rounds the name up to a cell, and over the flags.
.found:
        movzx   rax, byte [r14 + 8]     ; the name length once more
        lea     rax, [r14 + rax + 9]    ; one past the last character
        add     rax, 7
        and     rax, -8                 ; round up: the flags cell starts here
        add     rax, 8                  ; step over it to the code field
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
