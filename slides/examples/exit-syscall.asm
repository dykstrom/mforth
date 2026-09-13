; exit-syscall.asm - the smallest program this machine can run.
;
; Three instructions, no libc, and nothing printed. It asks the kernel to end
; the process with status 0, and that is the whole program. There is no way
; to make it smaller: a program has to end itself, and this is how.
;
; Read it before hello-syscall.asm. That one does the same thing and prints a
; line first, so everything here is there too: _start as the entry point, the
; call number in rax, and the arguments in rdi and the rest.
;
; Nothing follows the syscall. exit does not return, so there is no
; instruction after it to write - and no "ret" to write either, because there
; is nothing to return to. Leave the syscall out and the processor runs off
; the end of the code into whatever bytes come next.
;
; Build:  nasm -f elf64 exit-syscall.asm -o exit-syscall.o
;         clang -no-pie -nostdlib exit-syscall.o -o exit-syscall
;
; It prints nothing, so the shell is what shows it worked:
;
;     ./exit-syscall; echo $?

        global  _start                  ; the kernel starts the program here

        section .text
_start:
        ; exit(0)
        mov     eax, 60                 ; 60 is exit
        xor     edi, edi                ; exit status 0, the first argument
        syscall                         ; into the kernel, and the process
                                        ; is gone: nothing comes back
