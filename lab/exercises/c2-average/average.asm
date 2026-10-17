; average.asm - exercise C2: the mean of n doubles.
;
;     double average(const double *a, long n);
;
; a, the address of the first double, arrives in rdi; n, how many there are,
; in rsi. The answer leaves in xmm0. When n is 0, return 0.0.

        global  average

        section .text
average:
        ; TODO: add up the n doubles at rdi and divide by n
        pxor    xmm0, xmm0              ; return 0.0 for now
        ret
