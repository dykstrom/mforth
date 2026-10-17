; phase3.asm - tier D, phase 3: five characters, translated through a table.
;
;     int phase3(const char *input);
;
; The input has to be five characters long. Each character's low four bits,
; a number from 0 to 15, pick a byte of t2, and the five bytes picked have
; to spell t1, "forth". Only the low four bits count, so every character has
; several stand-ins: "gobij", "GOBIJ" and "7?29:" all pass.

        DEFAULT ABS

        global  phase3
        extern  strlen

        section .rodata
t1:     db      "forth", 0
t2:     db      "zkrqvmgfpthxuwlo", 0   ; f is at 7, o 15, r 2, t 9, h 10

        section .text
phase3:
        push    rbx                     ; callee-saved: given back before ret
        mov     rbx, rdi                ; the input, kept across strlen
        call    strlen                  ; the push left rsp a multiple of 16
        cmp     rax, 5
        jne     .wrong

        xor     ecx, ecx                ; i = 0
.next:
        movzx   eax, byte [rbx + rcx]   ; input[i]
        and     eax, 15                 ; its low four bits: 0 to 15
        movzx   eax, byte [t2 + rax]    ; the byte of the table they pick
        cmp     al, [t1 + rcx]          ; has to be t1[i]
        jne     .wrong
        inc     rcx
        cmp     rcx, 5
        jl      .next                   ; while i < 5

        mov     eax, 1
        pop     rbx
        ret
.wrong:
        xor     eax, eax
        pop     rbx
        ret
