; dot.asm - exercise C7: a dot product, four floats at a time.
;
;     float dot(const float *a, const float *b, long n);
;
; a arrives in rdi, b in rsi and n in rdx. Return a[0]*b[0] + a[1]*b[1] +
; ... + a[n-1]*b[n-1], a float, in the low 32 bits of xmm0. n is always a
; multiple of 4, and may be 0. Both arrays start on a 16-byte boundary.

        global  dot

        section .text
dot:
        ; TODO: multiply and add four at a time, then add the four sums
        xorps   xmm0, xmm0              ; return 0.0 for now
        ret
