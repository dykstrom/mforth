; mforth - a 64-bit indirect threaded code Forth for Linux/x86_64.
;
; This iteration defines. An inner interpreter runs threaded code, a dictionary
; holds every word under its name, an outer interpreter turns what a person
; types into words to run and numbers to push, and a compiler adds new words to
; the dictionary while the program runs. The program mforth runs is not written
; in this file: it is whatever arrives on standard input, including the words
; that arrive there as definitions.
;
; mforth uses the C library, so the entry point is main and not _start:
; libc's own startup code runs first and calls main, which means puts and
; the rest of libc are ready to use by the time this code runs.

        global  main                    ; libc's startup code calls main
        extern  puts                    ; puts(const char *) from libc
        extern  setvbuf                 ; setvbuf(FILE *, char *, int, size_t)
        extern  stdout                  ; libc's FILE * for standard output

; nasm is invoked on this file alone. Everything else arrives here, so the
; order below is the order the assembler sees: the NEXT macro and the macros
; that define a word have to come before the files that use them.
%include "include/mforth.inc"           ; registers, memory sizes, NEXT
%include "include/dictionary.inc"       ; what a word looks like in memory
%include "src/inner.asm"                ; the two stacks, docol and EXIT
%include "src/words.asm"                ; LIT, DUP, ., FIND, EXECUTE and more
%include "src/compiler.asm"             ; HERE, CREATE, ":" and ";"
%include "src/control.asm"              ; BRANCH, BEGIN, DO and the rest
%include "src/outer.asm"                ; the loop that reads and runs a line
%include "src/strings.asm"              ; EMIT, ." , .S and WORDS

        section .text
main:
        ; The System V ABI wants the stack 16-byte aligned at a call. The
        ; call into main pushed a return address and so knocked it 8 bytes
        ; out of alignment; subtracting 8 more puts it back. This is the only
        ; instruction in mforth that touches rsp. No word pushes or pops on
        ; the machine stack, so once this is done every libc call from every
        ; word is aligned.
        sub     rsp, 8

        ; libc decides how to buffer what a program prints by looking at where
        ; the output goes. A terminal is flushed at every newline. A pipe is
        ; not: libc holds the characters until 4096 of them have gathered or
        ; the process ends. mforth answers one line at a time and has to be
        ; seen doing it, so it asks for line buffering whichever it is. Without
        ; this, "make run" under "docker exec" without a terminal prints
        ; nothing at all until Ctrl-D, and then prints the whole session at
        ; once. It has to be asked before anything is printed.
        mov     rdi, [stdout]           ; the stream to change
        xor     esi, esi                ; libc keeps its own buffer
        mov     edx, 1                  ; _IOLBF: flush at every newline
        xor     ecx, ecx                ; of whatever size libc likes
        call    setvbuf

        mov     rdi, banner             ; first integer argument goes in rdi
        call    puts                    ; prints the string and a newline

        ; Start the Forth machine. Both stacks are empty, so each pointer sits
        ; at the top of its region.
        mov     DSP, data_stack_top
        mov     RSP, return_stack_top

        ; Where a walk through the dictionary starts. PREVIOUS_HEADER is a nasm
        ; %define that every header redefines to itself, so on this line it is
        ; the last header the assembler laid down, and a walk from here reaches
        ; every word. It has to be read after all of them, which is what puts
        ; it in this file: the %includes above are the whole dictionary.
        mov     qword [latest], PREVIOUS_HEADER

        ; Read the first line, then point IP at the one-cell thread that runs
        ; the interpreter. main never returns: BYE leaves through libc exit
        ; when the input runs out.
        call    refill
        test    rax, rax
        jz      code_bye                ; nothing on standard input at all
        mov     IP, interpreter
        NEXT

        section .rodata

; puts expects a NUL-terminated string and adds the newline itself.
banner: db      "mforth 0.10.0", 0
