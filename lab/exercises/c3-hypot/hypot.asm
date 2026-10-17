; hypot.asm - exercise C3: the length of the hypotenuse.
;
;     double hypot(double x, double y);
;
; x arrives in xmm0 and y in xmm1. The answer, the square root of x*x + y*y,
; leaves in xmm0.

        global  hypot

        section .text
hypot:
        ; TODO: square both, add them, take the square root
        pxor    xmm0, xmm0              ; return 0.0 for now
        ret
