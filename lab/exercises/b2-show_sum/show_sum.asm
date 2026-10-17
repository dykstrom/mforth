; show_sum.asm - exercise B2: print a sum with printf.
;
;     void show_sum(long a, long b);
;
; a arrives in rdi and b in rsi. Print them and their sum on one line,
;
;     printf("%ld + %ld = %ld\n", a, b, a + b);
;
; using the format below.

        global  show_sum
        extern  printf                  ; in libc, which the link brings in

        section .rodata
format: db      "%ld + %ld = %ld", 10, 0  ; 10 is the newline

        section .text
show_sum:
        ; TODO: call printf with the format, a, b and a + b
        ret
