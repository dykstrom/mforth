; solution.asm - exercise C5: print a double with printf.
;
;     void show(const char *label, double x);
;
; label arrives in rdi and x in xmm0. printf wants the format first, so the
; integer arguments all move along one register. The double does not move:
; it is printf's first floating-point argument as well as ours, and
; floating-point arguments are counted separately.

        global  show
        extern  printf

        section .rodata
format: db      "%s = %.2f", 10, 0      ; 10 is the newline, 0 ends the string

        section .text
show:
        ; At the call into show, rsp was a multiple of 16. The call pushed
        ; eight bytes of return address, so it is 8 off now. Eight more puts
        ; it back on a multiple of 16 for the call to printf.
        sub     rsp, 8

        ; Move label out of rdi before the format goes in there.
        mov     rsi, rdi                ; printf's second argument: label
        mov     rdi, format             ; its first: the format
                                        ; xmm0, x, is already in place

        ; printf takes any number of arguments, and cannot tell from its own
        ; signature whether any of them are doubles. al says how many vector
        ; registers carry arguments: here one, xmm0. Left at 0, printf never
        ; looks at xmm0 and prints whatever was in its memory instead.
        mov     eax, 1
        call    printf

        add     rsp, 8                  ; give back the eight bytes
        ret
