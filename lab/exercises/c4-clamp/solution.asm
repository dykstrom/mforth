; solution.asm - exercise C4: keep x between lo and hi.
;
;     double clamp(double x, double lo, double hi);
;
; x arrives in xmm0, lo in xmm1 and hi in xmm2, and the answer leaves in
; xmm0. When x is already in range it is the answer, so most of the time the
; function changes nothing.

        global  clamp

        section .text
clamp:
        ; ucomisd sets the flags the way an unsigned integer compare does:
        ; CF for below, ZF for equal. So the jumps after it are the unsigned
        ; ones, jb and ja. jl and jg read SF and OF, which ucomisd clears, so
        ; they assemble and run, and decide wrongly.
        ;
        ; A NaN is not below, above or equal to anything: the two are
        ; unordered, and ucomisd says so by setting PF, as well as CF and ZF.
        ; That CF would look like "below" to jb, so the NaN case goes first.
        ucomisd xmm0, xmm1              ; x against lo
        jp      .done                   ; x is NaN: return it as it is
        jb      .low                    ; x < lo

        ucomisd xmm0, xmm2              ; x against hi
        ja      .high                   ; x > hi
.done:
        ret                             ; x is in range, and already in xmm0

.low:
        movsd   xmm0, xmm1              ; the answer is lo
        ret

.high:
        movsd   xmm0, xmm2              ; the answer is hi
        ret
