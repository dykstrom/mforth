; solution.asm - exercise A2: the larger of two numbers.
;
;     long max(long a, long b);

        global  max

        section .text
max:
        ; Guess a, and keep the guess unless b turns out to be larger.
        mov     rax, rdi                ; rax = a

        ; cmp subtracts b from a and keeps only the flags. jge reads them as
        ; a signed comparison: jae would read them as unsigned, and call -1
        ; the largest number there is.
        cmp     rdi, rsi
        jge     .done                   ; a >= b: the guess was right
        mov     rax, rsi                ; otherwise the answer is b
.done:
        ret

        ; The same without a jump, using a conditional move:
        ;
        ;       mov     rax, rdi
        ;       cmp     rdi, rsi
        ;       cmovl   rax, rsi        ; if a < b, rax = b
        ;       ret
