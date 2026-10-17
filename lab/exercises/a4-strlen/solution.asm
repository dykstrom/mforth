; solution.asm - exercise A4: the length of a string.
;
;     size_t strlen(const char *s);

        global  strlen

        section .text
strlen:
        ; rax counts, and is the address of the next byte to look at as
        ; well: s + rax. When the byte there is 0, rax is the length.
        xor     eax, eax                ; length = 0
.next:
        ; byte says to compare one byte, not eight. Without it nasm cannot
        ; tell how much to read: neither [rdi + rax] nor 0 has a size.
        cmp     byte [rdi + rax], 0
        je      .done                   ; the 0 that ends the string
        inc     rax                     ; one more byte before it
        jmp     .next
.done:
        ret
