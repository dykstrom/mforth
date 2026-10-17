; solution.asm - exercise 01: return 42.
;
;     long answer(void);

        global  answer

        section .text
answer:
        mov     rax, 42                 ; the result goes back in rax
        ret                             ; and ret goes back to the caller
