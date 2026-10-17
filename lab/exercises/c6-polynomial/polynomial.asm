; polynomial.asm - exercise C6: a polynomial, by Horner's rule.
;
;     double polynomial(const double *c, long n, double x);
;
; c, the address of the first of n coefficients, arrives in rdi; n in rsi;
; x in xmm0. Return c[0] + c[1]*x + c[2]*x*x + ... + c[n-1]*x^(n-1), in
; xmm0. When n is 0, return 0.0.

        global  polynomial

        section .text
polynomial:
        ; TODO: start from c[n-1], and n-1 times multiply by x and add the next
        pxor    xmm0, xmm0              ; return 0.0 for now
        ret
