; hello-libc.asm - print a line through the C library.
;
; Linked the way mforth is linked, and built the same way: libc comes along,
; so the entry point is main and not _start. libc's own startup code runs
; first, sets the C library up, and calls main; returning from main is
; returning to that startup code, which ends the process for us.
;
; This is the System V call convention, the one every C function on this
; platform uses. The first integer argument goes in rdi, and the return
; value comes back in rax.
;
; Build:  nasm -f elf64 hello-libc.asm -o hello-libc.o
;         clang -no-pie hello-libc.o -o hello-libc
;
; -no-pie is what lets "mov rdi, msg" and "call puts" be written plainly.
; See ../../docs/adr/0001-link-non-pie.md.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc

        section .rodata
msg:    db      "Hello from libc", 0    ; C strings end in a zero byte, and
                                        ; puts adds the newline itself

        section .text
main:
        ; The System V ABI wants the stack 16-byte aligned at a call. The
        ; call into main pushed a return address and knocked it 8 bytes out;
        ; subtracting 8 more puts it back.
        sub     rsp, 8

        mov     rdi, msg                ; first integer argument goes in rdi
        call    puts

        xor     eax, eax                ; return 0 from main
        add     rsp, 8                  ; undo the alignment before returning
        ret
