; c_to_f.asm - exercise C1: Celsius to Fahrenheit.
;
;     double c_to_f(double c);
;
; c arrives in xmm0, and the answer leaves in xmm0. Work out c * 9 / 5 + 32.
; The three numbers have to be in memory: no instruction takes a double as an
; immediate. DEFAULT ABS is already here for when you load them.

        DEFAULT ABS

        global  c_to_f

        section .text
c_to_f:
        ; TODO: multiply by 9, divide by 5, add 32
        pxor    xmm0, xmm0              ; return 0.0 for now
        ret
