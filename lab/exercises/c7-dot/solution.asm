; solution.asm - exercise C7: a dot product, four floats at a time.
;
;     float dot(const float *a, const float *b, long n);
;
; a arrives in rdi, b in rsi and n in rdx. A float result leaves in the low
; 32 bits of xmm0.
;
; An xmm register holds four floats side by side, and the ps instructions
; work on all four at once: one mulps does four multiplies. So the loop keeps
; four running sums in xmm0, one per lane, and adds them together at the end.

        global  dot

        section .text
dot:
        xorps   xmm0, xmm0              ; four sums, all 0.0

        test    rdx, rdx                ; n is 0: the sum is 0.0
        jz      .done

        ; Four floats are 16 bytes, so i goes up by 4 and the address of
        ; a[i] is rdi + i*4.
        xor     ecx, ecx                ; i = 0
.next:
        ; movaps loads 16 bytes in one go. The a stands for aligned: the
        ; address must be a multiple of 16, or it faults. The test's arrays
        ; are aligned, and i only ever moves by 16 bytes. mulps can then
        ; read b straight from memory, which has the same rule.
        movaps  xmm1, [rdi + rcx*4]     ; a[i], a[i+1], a[i+2], a[i+3]
        mulps   xmm1, [rsi + rcx*4]     ; times b[i] .. b[i+3], lane by lane
        addps   xmm0, xmm1              ; add each product to its lane's sum
        add     rcx, 4
        cmp     rcx, rdx
        jl      .next                   ; while i < n

        ; The four lanes of xmm0 now hold s0 s1 s2 s3, from low to high.
        ; Fold them in half twice.
        movhlps xmm1, xmm0              ; xmm1's low half = s2 s3
        addps   xmm0, xmm1              ; lanes 0 and 1 = s0+s2, s1+s3
        movaps  xmm1, xmm0
        shufps  xmm1, xmm1, 1           ; lane 0 of xmm1 = lane 1 of xmm0
        addss   xmm0, xmm1              ; lane 0 = s0+s2 + s1+s3: the answer
.done:
        ret
