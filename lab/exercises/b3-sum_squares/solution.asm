; solution.asm - exercise B3: add up squares, calling square for each.
;
;     long sum_squares(long n);
;     long square(long x);              // in test.c
;
; n arrives in rdi, and the sum leaves in rax.
;
; Two numbers have to outlive every call to square: the count and the sum.
; square may change any caller-saved register, so they go in two
; callee-saved ones, rbx and r12. Counting down from n to 1 means n itself
; is the count, so two are enough.

        global  sum_squares
        extern  square

        section .text
sum_squares:
        ; rbx and r12 are callee-saved for whoever called sum_squares too:
        ; it expects them back as they were. Keep the old values on the stack.
        push    rbx
        push    r12

        ; On the way in rsp was 8 off a multiple of 16, and two pushes made
        ; it 24 off. 8 more makes 32, a multiple of 16, for the call.
        sub     rsp, 8

        mov     rbx, rdi                ; the count, from n down to 1
        xor     r12d, r12d              ; the sum, 0 so far

        test    rbx, rbx
        jz      .done                   ; n is 0: nothing to add up
.next:
        mov     rdi, rbx                ; argument 1: the number to square
        call    square                  ; rax = rbx * rbx. Anything else in
                                        ; rdi, rsi, rdx, rcx, r8 to r11 is gone
        add     r12, rax                ; sum += square
        dec     rbx                     ; and on to the number below
        jnz     .next                   ; until it reaches 0
.done:
        mov     rax, r12                ; the sum is the answer

        ; Undo it all in the opposite order: the 8 bytes, then the pushes.
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
