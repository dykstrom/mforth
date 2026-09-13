; hello-syscall.asm - print a line and exit, talking to the kernel directly.
;
; exit-syscall.asm is this program with the printing taken out. Everything
; below that is not the write call is already there.
;
; No libc. The entry point is _start, the first instruction the kernel runs
; after it has loaded the program; there is no startup code before it and
; nothing to return to after it, so the program has to end itself.
;
; A syscall has its own register convention, and it is not the one a C
; function call uses. The number of the call goes in rax, and the arguments
; go in rdi, rsi, rdx, r10, r8, r9. Note r10 where a call would use rcx: the
; syscall instruction puts the return address in rcx and the flags in r11,
; so those two registers cannot carry anything in.
;
; Build:  nasm -f elf64 hello-syscall.asm -o hello-syscall.o
;         clang -no-pie -nostdlib hello-syscall.o -o hello-syscall

        global  _start                  ; the kernel starts the program here

        section .rodata
msg:    db      "Hello from a syscall", 10
msglen  equ     $ - msg                 ; $ is the address here, so this is
                                        ; the length of what was just laid
                                        ; down: the assembler counts it

        section .text
_start:
        ; write(1, msg, msglen)
        mov     eax, 1                  ; 1 is write
        mov     edi, 1                  ; write to file descriptor 1, stdout
        mov     rsi, msg                ; the first byte to write
        mov     edx, msglen             ; how many bytes
        syscall                         ; into the kernel and back

        ; exit(0). Nothing returns from here: the process is gone.
        mov     eax, 60                 ; 60 is exit
        xor     edi, edi                ; exit status 0
        syscall
