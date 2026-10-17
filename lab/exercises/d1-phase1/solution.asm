; solution.asm - puzzle D1: the input phase 1 accepts.
;
;     int phase1(const char *input);
;
; How to find it, in ./debug d1:
;
;     disas
;
;         sub    rsp,0x8
;         movabs rsi,0x402040
;         call   0x401050 <strcmp@plt>
;         add    rsp,0x8
;         test   eax,eax
;         sete   al
;         ...
;
; The only call is to strcmp, and the input is in rdi already, so rsi is
; the string the input is compared against. movabs is mov with a 64-bit
; number, and the number is an address: 0x402040 is in the program's
; constants. Show what is there as a string:
;
;     x/s 0x402040
;
;         0x402040:   "Brackets mean memory"
;
; test eax, eax then asks whether strcmp returned 0, which it does only when
; the two strings are equal, and sete turns that into the 1 phase1 returns.
; The address moves with the length of your input, so read it from your
; own disas.

        global  input

        section .rodata
input:  db      "Brackets mean memory", 0
