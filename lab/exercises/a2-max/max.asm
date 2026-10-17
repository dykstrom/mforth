; max.asm - exercise A2: the larger of two numbers.
;
;     long max(long a, long b);
;
; a arrives in rdi and b in rsi. The larger one goes back in rax. Both are
; signed: -1 is less than 0.

        global  max

        section .text
max:
        ; TODO: return whichever of a and b is larger
        mov     rax, rdi                ; return a for now
        ret
