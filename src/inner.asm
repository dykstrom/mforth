; The two stacks, and the code that enters and leaves a word written in Forth.
; NEXT itself lives in include/mforth.inc, because every word ends with it.

        section .bss

; Both stacks grow downward, the way the machine's own stack does, so the label
; that matters is the one after the region. An empty stack has its pointer at
; the top, and a push subtracts 8 before storing.
data_stack:
        resb    DATA_STACK_SIZE
data_stack_top:

return_stack:
        resb    RETURN_STACK_SIZE
return_stack_top:

; docol ( R: -- ip ) starts a word whose body is a list of execution tokens.
;
; This is the code field of every word written in Forth, and it is the reason a
; Forth keeps a return stack of its own. W holds the execution token NEXT
; jumped through, so the body of the word begins one cell further on. IP still
; points into the thread that got here, and that address has to survive until
; the word ends: the return stack is where it waits.

        section .text
docol:
        sub     RSP, 8                  ; make room on the return stack
        mov     [RSP], IP               ; where to carry on when this word ends
        lea     IP, [W + 8]             ; the body starts after the code field
        NEXT

; EXIT ( R: ip -- ) ends a word written in Forth.
;
; The address docol saved is the place in the calling thread where execution
; carries on. Loading it back into IP is the return; the NEXT below then reads
; the caller's next token. A word that ends without EXIT would run straight
; into whatever data follows it.

        section .data
xt_exit:
        dq      code_exit

        section .text
code_exit:
        mov     IP, [RSP]               ; the caller's place in its own thread
        add     RSP, 8                  ; drop it from the return stack
        NEXT
