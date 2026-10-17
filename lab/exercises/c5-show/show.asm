; show.asm - exercise C5: print a double with printf.
;
;     void show(const char *label, double x);
;
; label arrives in rdi and x in xmm0. Print them with printf as
;
;     <label> = <x to two decimals>
;
; followed by a newline: show("pi", 3.14159) prints "pi = 3.14". The format
; that does it is "%s = %.2f", 10.

        global  show
        extern  printf                  ; in libc, not in this file

        section .text
show:
        ; TODO: call printf with the format, label and x
        ret
