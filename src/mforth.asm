; mforth - a 64-bit indirect threaded code Forth for Linux/x86_64.
;
; This iteration prints the banner and stops. There is no interpreter yet.
;
; mforth uses the C library, so the entry point is main and not _start:
; libc's own startup code runs first and calls main, which means puts and
; the rest of libc are ready to use by the time this code runs.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc

        section .text

main:
        ; The System V ABI wants the stack 16-byte aligned at a call. The
        ; call into main pushed a return address and so knocked it 8 bytes
        ; out of alignment; subtracting 8 more puts it back.
        sub     rsp, 8

        mov     rdi, banner             ; first integer argument goes in rdi
        call    puts                    ; prints the string and a newline

        xor     eax, eax                ; main returns 0: exit successfully

        add     rsp, 8                  ; undo the alignment adjustment
        ret

        section .rodata

; puts expects a NUL-terminated string and adds the newline itself.
banner: db      "mforth 0.1.0", 0
