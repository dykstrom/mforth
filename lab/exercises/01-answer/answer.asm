; answer.asm - exercise 01: return 42.
;
;     long answer(void);
;
; A function hands its result back in rax. That is the whole exercise: the
; point is to run ./check and ./debug once, before anything harder.

        global  answer                  ; so test.c, another file, can call it

        section .text
answer:
        mov     rax, 0                  ; TODO: return 42 instead
        ret
