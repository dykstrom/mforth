; mforth - a 64-bit indirect threaded code Forth for Linux/x86_64.
;
; This iteration has an inner interpreter, a data stack, a return stack, and a
; dictionary: every word carries its name, and a word can be looked up by that
; name while the program runs. There is still no way to read input, so the
; program it runs is the thread at the bottom of this file, written out by
; hand in the data section.
;
; mforth uses the C library, so the entry point is main and not _start:
; libc's own startup code runs first and calls main, which means puts and
; the rest of libc are ready to use by the time this code runs.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc

; nasm is invoked on this file alone. Everything else arrives here, so the
; order below is the order the assembler sees: the NEXT macro and the macros
; that define a word have to come before the files that use them.
%include "include/mforth.inc"           ; registers, stack sizes, NEXT
%include "include/dictionary.inc"       ; what a word looks like in memory
%include "src/inner.asm"                ; the two stacks, docol and EXIT
%include "src/words.asm"                ; LIT, DUP, ., FIND, EXECUTE and more

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
; The thread below reaches PRINT42 by looking its name up, exactly the way it
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

; The program mforth runs. It pushes 42, looks DUP up by name, and runs what
; FIND gives back, which leaves a second 42 on the stack. It then looks up a
; name that no word has, and prints the 0 that FIND returns instead. Last it
; looks up PRINT42 and runs that, which is a word written in Forth reached the
; same way DUP was.
;
; Nothing here names an execution token of a word it wants to run. That is what
; a dictionary is for: the thread holds a string, and the word that runs is
; whichever one carries that name.
thread:
        dq      xt_lit, 42              ; the number DUP is going to copy
        dq      xt_lit, name_dup        ; where the characters D U P are
        dq      xt_lit, 3               ; and how many of them there are
        dq      xt_find                 ; leaves DUP's execution token
        dq      xt_execute              ; runs it: now there are two 42s
        dq      xt_dot
        dq      xt_dot
        dq      xt_lit, name_nope       ; a name no word in the dictionary has
        dq      xt_lit, 4
        dq      xt_find                 ; the walk runs out of words, so 0
        dq      xt_dot
        dq      xt_cr                   ; end the line the three numbers made

        dq      xt_lit, name_print42    ; the word defined above, by name
        dq      xt_lit, 7
        dq      xt_find                 ; its code field holds docol, not code
        dq      xt_execute              ; docol enters it, EXIT leaves it again
        dq      xt_bye

        section .rodata

; puts expects a NUL-terminated string and adds the newline itself.
banner: db      "mforth 0.3.0", 0

; The names the thread looks up. FIND is given an address and a length, so
; these need no terminator.
name_dup:
        db      "DUP"
name_nope:
        db      "NOPE"
name_print42:
        db      "PRINT42"
