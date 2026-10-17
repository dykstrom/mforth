; phase1.asm - tier D, phase 1: the input has to be one particular string.
;
;     int phase1(const char *input);
;
; Returns 1 if input is the string at s1, and 0 if not. strcmp does the
; comparing, so the whole puzzle is finding what strcmp is handed besides
; the input.

        DEFAULT ABS

        global  phase1
        extern  strcmp

        section .rodata
s1:     db      "Brackets mean memory", 0

        section .text
phase1:
        sub     rsp, 8                  ; rsp a multiple of 16 for the call
        mov     rsi, s1                 ; strcmp(input, s1): input is in rdi already
        call    strcmp
        add     rsp, 8

        test    eax, eax                ; strcmp returns 0 when the two are equal
        sete    al                      ; al = 1 if it did, 0 if not
        movzx   eax, al                 ; and the rest of eax cleared
        ret
