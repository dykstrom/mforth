; The four words the hand-built thread needs. LIT reads a number out of the
; thread; the other three go through libc, which is why they arrive together.
;
; Every word here is written in two halves: a code field in .data holding the
; address of its machine code, and the machine code itself in .text. The two
; halves are kept next to each other so a word can be read in one place.
;
;      section .data                section .text
;
;   xt_cr -> +---------+
;            | code_cr | ---------> code_cr: mov  edi, 10
;            +---------+                     call putchar
;                                            NEXT
;
; CR is the whole shape: one cell in .data holding the address of the machine
; code, and the machine code itself in .text. There is no body. NEXT at the end
; is what carries on to the next word in the thread.
;
; Ticket 003 gives words names and a dictionary header, and that is the point
; at which the repetition below turns into a macro.

        extern  printf                  ; printf(const char *format, ...)
        extern  putchar                 ; putchar(int c)
        extern  exit                    ; exit(int status)

; LIT ( -- n ) pushes the number stored in the thread just after LIT.
;
; A number written in a program has to live somewhere, and in threaded code
; there is nowhere to put it but the thread itself. LIT reads the cell IP
; points at, which is that number rather than a word to run, and steps IP past
; it so that NEXT does not try to execute it.

        section .data
xt_lit:
        dq      code_lit

        section .text
code_lit:
        mov     rax, [IP]               ; the number sitting in the thread
        add     IP, 8                   ; step over it
        sub     DSP, 8                  ; make room on the data stack
        mov     [DSP], rax
        NEXT

; . ( n -- ) prints the top of the data stack, followed by one space.
;
; Forth's . leaves the space so that several numbers printed in a row can be
; told apart. printf does the work of turning a 64-bit number into digits;
; %ld is C's long, which on Linux/x86_64 is 64 bits wide.

        section .data
xt_dot:
        dq      code_dot

        section .text
code_dot:
        mov     rsi, [DSP]              ; the number to print
        add     DSP, 8                  ; drop it from the data stack
        mov     rdi, dot_format
        xor     eax, eax                ; printf is variadic: no vector args
        call    printf
        NEXT

; CR ( -- ) ends the line of output.

        section .data
xt_cr:
        dq      code_cr

        section .text
code_cr:
        mov     edi, 10                 ; the ASCII line feed
        call    putchar
        NEXT

; BYE ( -- ) leaves mforth.
;
; exit is libc's, not the kernel's: it flushes what printf has buffered before
; the process ends. It never returns, so this is the one word that does not end
; with NEXT.

        section .data
xt_bye:
        dq      code_bye

        section .text
code_bye:
        xor     edi, edi                ; exit status 0: nothing went wrong
        call    exit

        section .rodata

; printf wants its format as a NUL-terminated string. The space . leaves after
; the number is part of the format, so printing a number takes one call.
dot_format:
        db      "%ld ", 0
