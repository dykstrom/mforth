; solution.asm - exercise A1: the sum of two numbers.
;
;     long add(long a, long b);

        global  add

        section .text
add:
        ; add has two operands, and the left one is also the answer. Adding
        ; into rdi would leave the sum in the wrong register, so copy a to
        ; rax first and add b to that.
        mov     rax, rdi                ; rax = a
        add     rax, rsi                ; rax = a + b
        ret
