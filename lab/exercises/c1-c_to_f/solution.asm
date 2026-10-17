; solution.asm - exercise C1: Celsius to Fahrenheit.
;
;     double c_to_f(double c);
;
; A double argument arrives in xmm0, not rdi: floating-point arguments have
; registers of their own. A double result leaves in xmm0 as well, so c can be
; worked on where it already is.

        ; [nine] below means the absolute address of nine. The program is
        ; linked with -no-pie, so that address is a number the linker knows.
        DEFAULT ABS

        global  c_to_f

        ; No instruction takes a double as an immediate, so the constants live
        ; here. dq with a decimal point in it writes the bits of a double.
        section .rodata
nine:   dq      9.0
five:   dq      5.0
thirty_two:
        dq      32.0

        section .text
c_to_f:
        ; Each instruction reads its second operand straight from memory and
        ; leaves the result in xmm0, ready for the next one.
        mulsd   xmm0, [nine]            ; c * 9
        divsd   xmm0, [five]            ; / 5
        addsd   xmm0, [thirty_two]      ; + 32, and xmm0 is the answer
        ret
