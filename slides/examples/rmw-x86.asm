; rmw-x86.asm - read, modify and write a memory cell in one instruction.
;
; This is what CISC means in practice. "add [rax], rbx" names a register and
; a memory address, and the one instruction does all three parts of the work:
; it reads the eight bytes at the address, adds rbx to them, and writes the
; sum back. rmw-arm64.s does the same work where that is not allowed.
;
; Build:  nasm -f elf64 rmw-x86.asm -o rmw-x86.o
;         clang -no-pie rmw-x86.o -o rmw-x86

; Every address here is absolute: the program is linked with -no-pie, so a
; label is a number the linker knows and [cell] is the cell living at that
; number. nasm 3 asks to be told so instead of assuming it, exactly as
; include/mforth.inc tells it.
        DEFAULT ABS

        global  main
        extern  printf                  ; printf(const char *, ...)

        section .data                   ; .data, not .rodata: it is written to
cell:   dq      40                      ; one 64-bit cell holding 40

        section .rodata
fmt:    db      "cell = %ld", 10, 0

        section .text
main:
        ; push rbx does two things: rbx is callee-saved, so its old value has
        ; to come back, and the 8 bytes pushed realign the stack for the
        ; calls below.
        push    rbx

        mov     rdi, fmt                ; print the cell before the addition
        mov     rsi, [cell]
        xor     eax, eax                ; no arguments in vector registers
        call    printf

        mov     rax, cell               ; the address of the cell
        mov     rbx, 2                  ; the value to add into it
        add     [rax], rbx              ; read, add, write back: one instruction

        mov     rdi, fmt                ; and print it after
        mov     rsi, [cell]
        xor     eax, eax
        call    printf

        xor     eax, eax                ; return 0 from main
        pop     rbx
        ret
