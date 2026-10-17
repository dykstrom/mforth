; solution.asm - puzzle D3: the input phase 3 accepts.
;
;     int phase3(const char *input);
;
; How to find it, in ./debug d3. The addresses below are from one build;
; yours move with the length of your input, so read them from your own
; listing.
;
;     x/20i $pc
;
;         push   rbx
;         mov    rbx,rdi                ; keep the input
;         call   0x401030 <strlen@plt>
;         cmp    rax,0x5                ; it has to be five characters
;         jne    0x401317 <phase3.wrong>
;         xor    ecx,ecx                ; i = 0
;         movzx  eax,BYTE PTR [rbx+rcx*1]       ; input[i]
;         and    eax,0xf                ; its low four bits, 0 to 15
;         movzx  eax,BYTE PTR [rax+0x402046]    ; a byte of a table at 0x402046
;         cmp    al,BYTE PTR [rcx+0x402040]     ; has to be byte i of 0x402040
;         jne    0x401317 <phase3.wrong>
;         inc    rcx
;         cmp    rcx,0x5
;         jl     ...                    ; for all five
;
;     x/s 0x402040
;
;         0x402040:   "forth"
;
;     x/s 0x402046
;
;         0x402046:   "zkrqvmgfpthxuwlo"
;
; Count from 0 along the table to find each letter of "forth": f is at 7,
; o at 15, r at 2, t at 9 and h at 10. The input needs five characters
; whose low four bits are those numbers.
;
; In ASCII, the lowercase letters a to o are 0x61 to 0x6f, so their low four
; bits are 1 to 15: 7 is g, 15 is o, 2 is b, 9 is i and 10 is j. Hence
; "gobij". The uppercase letters A to O, 0x41 to 0x4f, end the same way, so
; "GOBIJ" passes too, and so does "7?29:" from 0x30 to 0x3f. The and throws
; the high four bits away, so phase3 never sees the difference.

        global  input

        section .rodata
input:  db      "gobij", 0
