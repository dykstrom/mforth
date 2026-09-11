; mforth - a 64-bit indirect threaded code Forth for Linux/x86_64.
;
; This iteration reads. An inner interpreter runs threaded code, a dictionary
; holds every word under its name, and an outer interpreter turns what a person
; types into words to run and numbers to push. The program mforth runs is no
; longer written in this file: it is whatever arrives on standard input.
;
; mforth uses the C library, so the entry point is main and not _start:
; libc's own startup code runs first and calls main, which means puts and
; the rest of libc are ready to use by the time this code runs.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc
        extern  setvbuf                 ; setvbuf(FILE *, char *, int, size_t)
        extern  stdout                  ; libc's FILE * for standard output

; nasm is invoked on this file alone. Everything else arrives here, so the
; order below is the order the assembler sees: the NEXT macro and the macros
; that define a word have to come before the files that use them.
%include "include/mforth.inc"           ; registers, memory sizes, NEXT
%include "include/dictionary.inc"       ; what a word looks like in memory
%include "src/inner.asm"                ; the two stacks, docol and EXIT
%include "src/words.asm"                ; LIT, DUP, ., FIND, EXECUTE and more
%include "src/outer.asm"                ; the loop that reads and runs a line

        section .text
main:
        ; The System V ABI wants the stack 16-byte aligned at a call. The
        ; call into main pushed a return address and so knocked it 8 bytes
        ; out of alignment; subtracting 8 more puts it back. No word touches
        ; rsp again, so once this is done every libc call from every word is
        ; aligned. Two subroutines do push: find_name and refill each save
        ; rbp and pop it back before they return, and that push is what keeps
        ; the call they make aligned in its turn.
        sub     rsp, 8

        ; libc decides how to buffer what a program prints by looking at where
        ; the output goes. A terminal is flushed at every newline. A pipe is
        ; not: libc holds the characters until 4096 of them have gathered or
        ; the process ends. mforth answers one line at a time and has to be
        ; seen doing it, so it asks for line buffering whichever it is. Without
        ; this, "make run" under "docker exec" without a terminal prints
        ; nothing at all until Ctrl-D, and then prints the whole session at
        ; once. It has to be asked before anything is printed.
        mov     rdi, [stdout]           ; the stream to change
        xor     esi, esi                ; libc keeps its own buffer
        mov     edx, 1                  ; _IOLBF: flush at every newline
        xor     ecx, ecx                ; of whatever size libc likes
        call    setvbuf

        mov     rdi, banner             ; first integer argument goes in rdi
        call    puts                    ; prints the string and a newline

        ; Start the Forth machine. Both stacks are empty, so each pointer sits
        ; at the top of its region.
        mov     DSP, data_stack_top
        mov     RSP, return_stack_top

        ; Read the first line, then point IP at the one-cell thread that runs
        ; the interpreter. main never returns: BYE leaves through libc exit
        ; when the input runs out.
        call    refill
        test    rax, rax
        jz      code_bye                ; nothing on standard input at all
        mov     IP, interpreter
        NEXT

; PRINT42 ( -- ) prints 42 and ends the line.
;
; This is what a definition written in Forth looks like in memory. Its header
; is the same one a word written in assembly has. What differs is the code
; field: it holds docol, and the execution tokens of the words to run follow
; it.
;
;                        section .data              section .text
;
;   header_print42 -> +------------------+
;                     | link             |   the word defined before PRINT42
;                     | 7 P R I N T 4 2  |   the name: a length, then characters
;                     | flags = 0        |
;   xt_print42 ->     | docol            | -------> docol: sub RSP, 8
;                     +------------------+                 mov [RSP], IP
;                     | xt_lit           | -.              lea IP, [W + 8]
;                     |    42            |  |              NEXT
;                     | xt_dot           |  |- the body
;                     | xt_cr            |  |
;                     | xt_exit          | -'
;                     +------------------+
;
; The interpreter reaches PRINT42 by looking its name up, exactly the way it
; reaches DUP: nothing that runs a word has to know which of the two kinds it
; is. Ticket 006 makes the interpreter build a definition like this one while
; it runs; here it is assembled by hand.
        defword "PRINT42", print42
        dq      xt_lit, 42
        dq      xt_dot
        dq      xt_cr
        dq      xt_exit

        section .data

; Where a walk through the dictionary starts: the word defined last, which is
; PRINT42 just above. FIND follows the links back from here, so this cell has
; to be written after every word, and PRINT42 is defined in this file rather
; than in src/words.asm. Ticket 006 turns it into a variable that the compiler
; updates as it defines words.
latest:
        dq      PREVIOUS_HEADER

        section .rodata

; puts expects a NUL-terminated string and adds the newline itself.
banner: db      "mforth 0.5.0", 0
