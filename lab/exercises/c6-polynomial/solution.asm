; solution.asm - exercise C6: a polynomial, by Horner's rule.
;
;     double polynomial(const double *c, long n, double x);
;
; c arrives in rdi, n in rsi and x in xmm0. The answer leaves in xmm0.
;
; Horner's rule writes 1 + 2x + 3x^2 as ((3)x + 2)x + 1: start from the last
; coefficient, then over and over multiply by x and add the next one down.
; No powers of x, and one running value, which lives in xmm0.

        global  polynomial

        section .text
polynomial:
        ; xmm0 is where the answer has to end up, so x moves out of the way.
        movsd   xmm1, xmm0              ; x
        pxor    xmm0, xmm0              ; sum = 0.0

        ; n is 0: nothing to add up, and the 0.0 is the answer.
        test    rsi, rsi
        jz      .done

        ; rsi counts down from n to 1, and c[rsi - 1] is the coefficient to
        ; add: c[n-1] first, c[0] last. The first time round the sum is 0.0,
        ; so multiplying it by x does nothing and the loop needs no special
        ; start.
.next:
        mulsd   xmm0, xmm1              ; sum = sum * x
        addsd   xmm0, [rdi + rsi*8 - 8] ; + c[rsi - 1]
        dec     rsi                     ; dec sets the zero flag when it
        jnz     .next                   ; reaches 0, so no cmp is needed
.done:
        ret
