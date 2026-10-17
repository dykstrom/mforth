; solution.asm - exercise C2: the mean of n doubles.
;
;     double average(const double *a, long n);
;
; a arrives in rdi and n in rsi, the two integer argument registers. The
; answer leaves in xmm0, the first floating-point one: integers and floats
; are counted separately, so a function can take integers and still return a
; double.

        global  average

        section .text
average:
        ; xor of a register with itself is zero in any register file. For
        ; xmm0 the zero is all 64 bits clear in the low half, which is 0.0.
        pxor    xmm0, xmm0              ; sum = 0.0

        ; Nothing to add up, and 0.0 / 0 would be NaN. Return the 0.0.
        test    rsi, rsi
        jz      .done

        ; Element i lives at rdi + i*8: eight bytes to a double. addsd can
        ; read its second operand straight from memory, so the loop needs no
        ; register to hold the element in.
        xor     ecx, ecx                ; i = 0
.next:
        addsd   xmm0, [rdi + rcx*8]     ; sum += a[i]
        inc     rcx
        cmp     rcx, rsi
        jl      .next                   ; while i < n

        ; divsd divides doubles only, so n has to become one first.
        ; cvtsi2sd: convert signed integer to scalar double.
        cvtsi2sd xmm1, rsi
        divsd   xmm0, xmm1              ; sum / n, left in xmm0 to return
.done:
        ret
