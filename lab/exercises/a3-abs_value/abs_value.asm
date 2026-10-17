; abs_value.asm - exercise A3: a number without its sign.
;
;     long abs_value(long x);
;
; x arrives in rdi. Its absolute value goes back in rax: x itself if it is
; zero or more, -x if it is negative.

        global  abs_value

        section .text
abs_value:
        ; TODO: return -x when x is negative
        mov     rax, rdi                ; return x as it is, for now
        ret
