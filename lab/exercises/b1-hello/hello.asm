; hello.asm - exercise B1: print a line with puts.
;
;     void hello(void);
;
; puts, from the C library, prints a string and a newline after it. It takes
; the string's address in rdi, the first argument register. The string has
; to end in a zero byte, which is how puts knows where it stops.

        global  hello
        extern  puts                    ; in libc, which the link brings in

        section .rodata
msg:    db      "Hello, world!", 0

        section .text
hello:
        ; TODO: call puts with the address of msg
        ret
