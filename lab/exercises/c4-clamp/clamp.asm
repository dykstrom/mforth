; clamp.asm - exercise C4: keep x between lo and hi.
;
;     double clamp(double x, double lo, double hi);
;
; x arrives in xmm0, lo in xmm1 and hi in xmm2. Return lo if x is below lo,
; hi if x is above hi, and x otherwise. If x is NaN, return it as it is.
; The answer leaves in xmm0.

        global  clamp

        section .text
clamp:
        ; TODO: compare x with lo and with hi
        ret                             ; returns x unchanged for now
