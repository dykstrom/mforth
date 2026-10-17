; solution.asm - puzzle D2: the input phase 2 accepts.
;
;     int phase2(const char *input);
;
; How to find it, in ./debug d2. The addresses below are from one build;
; yours move with the length of your input, so read them from your own
; listing.
;
;     x/24i $pc
;
; The first call is to sscanf, and the lines before it set up its
; arguments:
;
;         sub    rsp,0x28
;         movabs rsi,0x402040           ; the format
;         lea    rdx,[rsp]              ; and four addresses on the stack,
;         lea    rcx,[rsp+0x8]          ; eight bytes apart: room for four
;         lea    r8,[rsp+0x10]          ; longs, n[0] to n[3]
;         lea    r9,[rsp+0x18]
;         xor    eax,eax
;         call   0x401070 <sscanf@plt>
;
;     x/s 0x402040
;
;         0x402040:   "%ld %ld %ld %ld"
;
; So the input is four numbers. What follows says which:
;
;         cmp    eax,0x4                ; sscanf read all four,
;         jne    0x40133e <phase2.wrong>
;         cmp    QWORD PTR [rsp],0x2    ; and n[0] is 2
;         jne    0x40133e <phase2.wrong>
;         mov    ecx,0x1                ; then for i = 1, 2, 3:
;         mov    rax,QWORD PTR [rsp+rcx*8-0x8]  ; n[i-1]
;         imul   rax,rax,0x3            ;   times 3
;         dec    rax                    ;   less 1
;         cmp    rax,QWORD PTR [rsp+rcx*8]      ; has to be n[i]
;         jne    0x40133e <phase2.wrong>
;
; 2, then 2 * 3 - 1 = 5, 5 * 3 - 1 = 14, and 14 * 3 - 1 = 41.
;
; With any four numbers in the input, x/4gd $rsp after the call shows them
; where sscanf put them, and the cmp that fails shows which one is wrong.

        global  input

        section .rodata
input:  db      "2 5 14 41", 0
