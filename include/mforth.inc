; Conventions the rest of mforth is written against: the registers that make up
; the Forth machine, the size of its two stacks, and NEXT, the inner
; interpreter every word ends with.

; Every address in mforth is absolute. The binary is linked with -no-pie, so
; a label is a number the linker knows, and [latest] is the cell living at
; that number. nasm 3 asks to be told so instead of assuming it.
        DEFAULT ABS

; The Forth machine keeps four values in registers.
;
; rbx, r12 and r13 are callee-saved in the System V ABI: a function that uses
; them has to give them back unchanged. That is what lets a word call printf
; and find IP, DSP and RSP untouched when the call returns. Had they been put
; in caller-saved registers, every word that talks to libc would have to save
; and restore all three around the call.
;
; RSP below is Forth's return stack pointer. It has nothing to do with the
; machine's rsp, which is set up once in main and never touched again.
%define IP      rbx             ; address of the next execution token to run
%define DSP     r12             ; data stack pointer: address of the top item
%define RSP     r13             ; return stack pointer: address of the top item
%define W       rax             ; the word being entered right now

; W is live only from the jump at the end of NEXT until the code jumped to has
; read it, and docol is the only code that reads it. Everywhere else rax is
; free to use as a scratch register.

; 8192 cells each. Nothing checks either stack for overflow or underflow. A
; test on every push and pop would be more code to read than the interpreter
; it protects, and until the interpreter reads input there is no way to ask
; for an item that is not there.
DATA_STACK_SIZE   equ 65536
RETURN_STACK_SIZE equ 65536

; NEXT is the inner interpreter: the three instructions that run at the end of
; every word to start the next one.
;
; IP walks along a thread, which is a list of execution tokens. An execution
; token is the address of a word's code field, and the code field holds the
; address of the machine code to run. NEXT loads the token, then jumps through
; the code field it points at. That second step is the indirection that gives
; indirect threaded code its name, and it is why a word can be entered without
; the code that enters it knowing whether the word is written in assembly or
; in Forth.
%macro NEXT 0
        mov     W, [IP]                 ; the execution token IP points at
        add     IP, 8                   ; step past it, ready for next time
        jmp     [W]                     ; jump through the word's code field
%endmacro
