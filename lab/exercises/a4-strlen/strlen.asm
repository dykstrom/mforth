; strlen.asm - exercise A4: the length of a string.
;
;     size_t strlen(const char *s);
;
; s, the address of the first character, arrives in rdi. The string ends at
; the first byte that is 0. The number of bytes before that one goes back in
; rax.

        global  strlen

        section .text
strlen:
        ; TODO: count the bytes before the 0
        xor     eax, eax                ; return 0 for now
        ret
