; add.asm - exercise A1: the sum of two numbers.
;
;     long add(long a, long b);
;
; a arrives in rdi and b in rsi, the first two argument registers. The sum
; goes back in rax.

        global  add

        section .text
add:
        ; TODO: return a + b
        xor     eax, eax                ; return 0 for now
        ret
