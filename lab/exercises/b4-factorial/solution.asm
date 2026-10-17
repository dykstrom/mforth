; solution.asm - exercise B4: n!, by calling itself.
;
;     long factorial(long n);
;
; n arrives in rdi, and n! leaves in rax.

        global  factorial

        section .text
factorial:
        ; 0! and 1! are both 1, and the recursion stops here. cmp and jg are
        ; signed, so a negative n stops here too, rather than counting down
        ; for ever.
        cmp     rdi, 1
        jg      .recurse
        mov     eax, 1                  ; writing eax clears the rest of rax
        ret

.recurse:
        ; n is needed after the call, to multiply by, but the call is free to
        ; change rdi, and the call below does: it passes n - 1 in it. So n
        ; goes on the stack, where nothing the call does can reach it.
        ;
        ; The push does a second job. On the way in rsp was 8 off a multiple
        ; of 16; after 8 more it is on one, ready for the call.
        push    rdi

        dec     rdi                     ; argument 1: n - 1
        call    factorial               ; rax = (n - 1)!

        ; Every call below this one has pushed and popped its own n by now,
        ; so the top of the stack is this call's n again.
        pop     rdi
        imul    rax, rdi                ; n * (n - 1)!
        ret
