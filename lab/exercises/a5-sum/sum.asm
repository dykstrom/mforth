; sum.asm - exercise A5: the sum of n numbers.
;
;     long sum(const long *a, long n);
;
; a, the address of the first number, arrives in rdi; n, how many there are,
; in rsi. The sum goes back in rax. When n is 0, the sum is 0.

        global  sum

        section .text
sum:
        ; TODO: add up the n numbers at rdi
        xor     eax, eax                ; return 0 for now
        ret
