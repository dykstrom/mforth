; phase2.asm - tier D, phase 2: four numbers, each made from the one before.
;
;     int phase2(const char *input);
;
; sscanf reads four longs from the input into an array on the stack. The
; first has to be 2, and every other one three times the one before it,
; less 1: 2 5 14 41.

        DEFAULT ABS

        global  phase2
        extern  sscanf

        section .rodata
f1:     db      "%ld %ld %ld %ld", 0

        section .text
phase2:
        ; Four longs, 32 bytes, at rsp. The call left rsp 8 off a multiple
        ; of 16; 40 more puts it back on one, ready for sscanf.
        sub     rsp, 40

        ; sscanf(input, f1, &n[0], &n[1], &n[2], &n[3])
        mov     rsi, f1                 ; input is in rdi already
        lea     rdx, [rsp]
        lea     rcx, [rsp + 8]
        lea     r8, [rsp + 16]
        lea     r9, [rsp + 24]
        xor     eax, eax                ; variadic: no vector registers used
        call    sscanf
        cmp     eax, 4                  ; how many numbers it read
        jne     .wrong

        cmp     qword [rsp], 2          ; n[0] == 2
        jne     .wrong

        ; for i = 1 to 3: n[i] == n[i-1] * 3 - 1
        mov     ecx, 1
.next:
        mov     rax, [rsp + rcx*8 - 8]  ; n[i-1]
        imul    rax, rax, 3
        dec     rax
        cmp     rax, [rsp + rcx*8]      ; n[i]
        jne     .wrong
        inc     rcx
        cmp     rcx, 4
        jl      .next

        mov     eax, 1
        add     rsp, 40
        ret
.wrong:
        xor     eax, eax
        add     rsp, 40
        ret
