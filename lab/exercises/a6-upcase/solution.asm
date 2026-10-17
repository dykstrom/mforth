; solution.asm - exercise A6: a string in capitals, changed where it lies.
;
;     void upcase(char *s);

        global  upcase

        section .text
upcase:
        ; movzx reads one byte into the bottom of eax and fills the rest
        ; with zeros: move with zero extend. Writing eax clears the top half
        ; of rax as well, so all 64 bits hold just this character.
.next:
        movzx   eax, byte [rdi]         ; c = *s
        test    al, al
        jz      .done                   ; the 0 that ends the string

        ; A lowercase letter is one from 'a' to 'z'. nasm turns a character
        ; in quotes into its number, so 'a' is 97.
        cmp     al, 'a'
        jb      .skip                   ; below 'a': not a letter to change
        cmp     al, 'z'
        ja      .skip                   ; above 'z': not one either

        ; In ASCII each capital is 32 below its lowercase letter: 'A' is 65,
        ; 'a' is 97. al names one byte, so the store writes one byte back.
        sub     al, 32
        mov     [rdi], al               ; *s = c - 32
.skip:
        inc     rdi                     ; s++
        jmp     .next
.done:
        ret
