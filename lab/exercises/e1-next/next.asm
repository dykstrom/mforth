; next.asm - exercise E1: NEXT, the inner interpreter.
;
;     long *forth(const void *const *thread, long *stack);
;
; This file is the whole Forth so far: the way in from C, NEXT, and two
; words, LIT and BYE. NEXT is this exercise's part, at the label next.
; tiers/e-forth.md explains the rest.

; The Forth machine's registers, the same ones mforth uses. rbx and r12 are
; callee-saved: a function called from a word, printf say, has to give them
; back unchanged. W is live only from NEXT's jump until the word has started,
; so every word is free to use rax as a scratch register.
%define IP      rbx             ; address of the next execution token to run
%define DSP     r12             ; data stack pointer: address of the top item
%define W       rax             ; the word being entered right now

; forth is how the test gets in. The execution tokens are how it writes a
; thread. The machine code of each word needs no global: only NEXT jumps to
; it, and NEXT finds it through the code field.
;
; ":data 8" marks a code field as eight bytes of data. gdb then knows the
; name of an address it sees in a thread, and x/a shows <xt_lit> rather than
; a bare number.
        global  forth
        global  xt_lit:data 8
        global  xt_bye:data 8

        section .text

; forth - the way in from C.
;
; Runs the thread, with the data stack starting out empty at stack, until
; the thread reaches BYE. Returns DSP as BYE found it, so the test can read
; what the thread left on the stack.
;
; The call that got here pushed eight bytes, and the two pushes below make
; 24. Eight more makes rsp a multiple of 16 again, and no word moves rsp, so
; a word can call printf as it stands.
forth:
        push    rbx                     ; IP and DSP are callee-saved, so the
        push    r12                     ; C side gets them back, from BYE
        sub     rsp, 8                  ; rsp a multiple of 16, for printf
        mov     IP, rdi                 ; the first token of the thread
        mov     DSP, rsi                ; an empty stack: nothing pushed yet
        jmp     next                    ; start the first word

; NEXT - start the word whose execution token IP points at. Every word ends
; by jumping here.
;
; mforth pastes these same three instructions into the end of every word,
; with a macro. Here every word jumps to this one copy instead. That costs a
; jump, and buys a single place for gdb to stop at between words: b next.
next:
        ; TODO: load the execution token IP points at into W, step IP past
        ; it, and jump through the code field W points at
        jmp     bye                     ; for now: stop before the first word

; LIT ( -- n ) pushes the number in the cell after it in the thread.
;
; NEXT has already stepped IP past LIT's own token, so IP points at the
; number. LIT steps over that too, or NEXT would run the number as a token.
        section .rodata
xt_lit: dq      lit                     ; the code field: where LIT's code is

        section .text
lit:
        mov     rax, [IP]               ; the number sitting in the thread
        add     IP, 8                   ; step over it
        sub     DSP, 8                  ; make room on the data stack
        mov     [DSP], rax
        jmp     next

; BYE ( -- ) leaves the Forth, back to the C that called forth.
;
; It undoes what forth did, in the opposite order, and returns DSP. mforth's
; BYE calls exit instead: there, nothing is waiting for an answer. It is the
; one word that does not end by jumping to next.
        section .rodata
xt_bye: dq      bye

        section .text
bye:
        mov     rax, DSP                ; the answer: where the stack ended
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
