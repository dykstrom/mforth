; sum_squares.asm - exercise B3: add up squares, calling square for each.
;
;     long sum_squares(long n);
;     long square(long x);              // in test.c
;
; n arrives in rdi, and the sum 1*1 + 2*2 + ... + n*n leaves in rax. Get
; each square by calling square, which the test provides. square may change
; any caller-saved register, and does. When n is 0, return 0.

        global  sum_squares
        extern  square                  ; in test.c

        section .text
sum_squares:
        ; TODO: call square for each of 1 to n, and add up what it returns
        xor     eax, eax                ; return 0 for now
        ret
