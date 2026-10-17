; solution.asm - exercise B2: print a sum with printf.
;
;     void show_sum(long a, long b);
;
; a arrives in rdi and b in rsi. printf wants the format first, so every
; argument moves up one register: the format in rdi, a in rsi, b in rdx and
; the sum in rcx.

        global  show_sum
        extern  printf

        section .rodata
format: db      "%ld + %ld = %ld", 10, 0  ; 10 is the newline

        section .text
show_sum:
        ; rsp is 8 off a multiple of 16 on the way in, and the call to
        ; printf must be made with it on one.
        sub     rsp, 8

        ; Fill the registers from the last argument back to the first. Each
        ; one is written only after what was in it has been copied on: mov
        ; rsi, rdi first would lose b before it reached rdx.
        ;
        ; lea works out rdi + rsi the way it works out an address, and keeps
        ; the number without reading memory. Unlike add, it leaves both
        ; operands as they were.
        lea     rcx, [rdi + rsi]        ; argument 4: a + b
        mov     rdx, rsi                ; argument 3: b
        mov     rsi, rdi                ; argument 2: a
        mov     rdi, format             ; argument 1: the format

        ; printf takes any number of arguments, and al tells it how many of
        ; them came in xmm registers. None did. Writing eax clears all of
        ; rax, al included.
        xor     eax, eax
        call    printf

        add     rsp, 8                  ; back to the return address
        ret
