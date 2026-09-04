; mforth - a 64-bit indirect threaded code Forth for Linux/x86_64.
;
; This iteration has an inner interpreter, a data stack, a return stack and
; four words. It has no dictionary and no way to read input, so the program it
; runs is the thread at the bottom of this file, written out by hand in the
; data section.
;
; mforth uses the C library, so the entry point is main and not _start:
; libc's own startup code runs first and calls main, which means puts and
; the rest of libc are ready to use by the time this code runs.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc

; nasm is invoked on this file alone. Everything else arrives here, so the
; order below is the order the assembler sees: the NEXT macro has to be
; defined before the files that use it.
%include "include/mforth.inc"           ; registers, stack sizes, NEXT
%include "src/inner.asm"                ; the two stacks, docol and EXIT
%include "src/words.asm"                ; LIT, . , CR and BYE

        section .text
main:
        ; The System V ABI wants the stack 16-byte aligned at a call. The
        ; call into main pushed a return address and so knocked it 8 bytes
        ; out of alignment; subtracting 8 more puts it back. This is the only
        ; instruction in mforth that touches rsp. No word pushes or pops on
        ; the machine stack, so once this is done every libc call from every
        ; word is aligned.
        sub     rsp, 8

        mov     rdi, banner             ; first integer argument goes in rdi
        call    puts                    ; prints the string and a newline

        ; Start the Forth machine. Both stacks are empty, so each pointer sits
        ; at the top of its region.
        mov     DSP, data_stack_top
        mov     RSP, return_stack_top

        ; Point IP at the program and run its first word. main never returns:
        ; the thread ends with BYE, which leaves through libc exit.
        mov     IP, thread
        NEXT

; print42 ( -- ) prints 42 and ends the line.
;
; This is what a definition written in Forth looks like in memory: a code field
; pointing at docol, the execution tokens of the words to run, and EXIT to
; finish. Ticket 006 makes the interpreter build one of these while it runs;
; here it is assembled by hand.
;
;         section .data                   section .text
;
;   xt_print42 -> +----------+
;                 |  docol   | ---------> docol: sub RSP, 8
;                 +----------+                   mov [RSP], IP
;                 |  xt_lit  | -.                lea IP, [W + 8]
;                 |    42    |  |                NEXT
;                 |  xt_dot  |  |- the body
;                 |  xt_cr   |  |
;                 |  xt_exit | -'
;                 +----------+
;
; The code field is the same one cell a primitive has, so the thread below runs
; print42 exactly the way it runs BYE. What differs is where that cell points:
; at docol, which pushes IP and steps into the body, rather than at machine code
; that does the work itself. That is the indirection NEXT jumps through.

        section .data
xt_print42:
        dq      docol
        dq      xt_lit, 42
        dq      xt_dot
        dq      xt_cr
        dq      xt_exit

; The program mforth runs. print42 appears twice to show that EXIT really does
; come back to the thread that entered the word, and that the return stack is
; where it comes back from. BYE stops the machine.
thread:
        dq      xt_print42
        dq      xt_print42
        dq      xt_bye

        section .rodata

; puts expects a NUL-terminated string and adds the newline itself.
banner: db      "mforth 0.2.0", 0
