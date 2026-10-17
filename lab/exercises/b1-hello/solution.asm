; solution.asm - exercise B1: print a line with puts.
;
;     void hello(void);

        global  hello
        extern  puts                    ; in libc, which the link brings in

        section .rodata
msg:    db      "Hello, world!", 0      ; no newline: puts adds one

        section .text
hello:
        ; The call that came here pushed its return address, so rsp is 8 off
        ; a multiple of 16. Every call has to be made with rsp a multiple of
        ; 16, puts included, so move it the rest of the way.
        sub     rsp, 8

        ; -no-pie makes msg a plain number the linker knows, and puts a name
        ; it can call. Under the default, PIE, neither line would link as
        ; written.
        mov     rdi, msg                ; argument 1: the string's address
        call    puts

        ; Give the 8 bytes back, so that ret finds the return address on top.
        add     rsp, 8
        ret
