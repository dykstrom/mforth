; factorial.asm - exercise B4: n!, by calling itself.
;
;     long factorial(long n);
;
; n arrives in rdi, and n! = 1 * 2 * ... * n leaves in rax. 0! is 1. Write
; it the recursive way: 1 when n is 0 or 1, and otherwise n times what
; factorial(n - 1) returns.

        global  factorial

        section .text
factorial:
        ; TODO: return 1 for n <= 1, otherwise n * factorial(n - 1)
        xor     eax, eax                ; return 0 for now
        ret
