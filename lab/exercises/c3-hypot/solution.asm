; solution.asm - exercise C3: the length of the hypotenuse.
;
;     double hypot(double x, double y);
;
; Two double arguments take the first two floating-point registers: x in
; xmm0, y in xmm1. The answer leaves in xmm0.

        global  hypot

        section .text
hypot:
        mulsd   xmm0, xmm0              ; x * x
        mulsd   xmm1, xmm1              ; y * y. No xmm register is
                                        ; callee-saved, so xmm1 is ours to use
        addsd   xmm0, xmm1              ; x*x + y*y

        ; sqrtsd takes the root of its second operand and writes it to the
        ; first. Here both are xmm0.
        sqrtsd  xmm0, xmm0
        ret
