; solution.asm - exercise A3: a number without its sign.
;
;     long abs_value(long x);

        global  abs_value

        section .text
abs_value:
        mov     rax, rdi                ; rax = x

        ; test ands x with itself and keeps only the flags. The sign flag is
        ; the top bit of the result, which is the top bit of x: set exactly
        ; when x is negative. jns jumps when it is not set.
        test    rax, rax
        jns     .done                   ; x >= 0: x is the answer
        neg     rax                     ; otherwise rax = 0 - x
.done:
        ret

        ; neg of the most negative number, -9223372036854775808, is that
        ; number again: +9223372036854775808 needs one bit more than 64.
