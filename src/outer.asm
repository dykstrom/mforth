; The outer interpreter: the loop that reads what a person types and runs it.
;
; The inner interpreter walks a thread of execution tokens. The outer one makes
; those tokens out of text. It reads a line, splits it into words, and for each
; word either runs the word of that name or pushes the number the text spells.
; That loop is the whole of what an interactive Forth does.
;
; This loop is one cell of thread rather than a word written in Forth:
;
;                    section .data
;
;   interpreter -> +------------------+
;                  | xt_interpret     |   the only cell in the thread
;                  +------------------+
;
; INTERPRET points IP back at that cell before it does anything else, so every
; word it runs returns to it through that word's own NEXT. A real Forth calls
; this loop QUIT and writes it in Forth as INTERPRET followed by a branch back.
; BRANCH exists now, in src/control.asm, so mforth could. It does not: the loop
; being data rather than a word is a decision of its own, recorded in
; docs/adr/0005-interpreter-loop-in-one-cell-of-thread.md, and changing it
; would supersede that decision rather than edit it.

        extern  getchar                 ; getchar(void)

        section .bss

input_buffer:
        resb    INPUT_BUFFER_SIZE
input_length:
        resq    1                       ; characters the line holds
input_offset:
        resq    1                       ; how far along it parse_word has got

; The word parse_word handed back last. INTERPRET needs it a second time when
; the word turns out to be neither a word nor a number, to name it back.
word_address:
        resq    1
word_length:
        resq    1

        section .rodata

; puts adds the newline. The leading space keeps ok clear of what the line
; printed: 3 . leaves "3 " and the answer makes it "3  ok".
ok_message:
        db      " ok", 0

; %.*s takes the length first and the characters second, so the name needs no
; terminator. That matters: the name is still sitting in the input buffer.
unknown_format:
        db      "%.*s ?", 10, 0

        section .data

; The thread the Forth machine runs. One cell, holding the word below.
interpreter:
        dq      xt_interpret

        section .text

; refill reads one line into the input buffer. It leaves 1 in rax when there is
; a line to interpret, and 0 when the input has run out.
;
; getchar leaves the character in eax, or -1 at end of input. The line feed
; ends the line and is not stored, so parse_word only ever walks over spaces,
; tabs and the characters of words. End of input after some characters ends the
; line the way a line feed does; end of input before any ends the session.
;
;   in    none  the line comes from standard input
;   out   rax   1 when a line was read, 0 when the input has run out
;
; The line itself is not a return value in a register: refill leaves it in
; input_buffer, with its length in input_length and input_offset back at 0.
refill:
        push    rbp                     ; the count has to outlive getchar
        xor     ebp, ebp                ; characters stored so far
.next_char:
        call    getchar
        cmp     eax, -1
        je      .end_of_input
        cmp     eax, 10                 ; the line feed ends the line
        je      .end_of_line
        cmp     rbp, INPUT_BUFFER_SIZE  ; keep reading, but store nothing more
        jae     .next_char
        mov     [input_buffer + rbp], al
        inc     rbp
        jmp     .next_char

.end_of_input:
        test    rbp, rbp                ; were there characters before it?
        jz      .no_more_input

.end_of_line:
        mov     [input_length], rbp
        mov     qword [input_offset], 0 ; parse_word starts at the beginning
        mov     eax, 1
        pop     rbp
        ret

.no_more_input:
        xor     eax, eax
        pop     rbp
        ret

        section .text

; parse_word takes the next word off the line. It leaves the address of the
; word's first character in rax and the number of characters in rdx, and leaves
; 0 in rdx when the line holds nothing more.
;
;   in    none  the line is in input_buffer, the place reached in input_offset
;   out   rax   where the word's first character is
;         rdx   how many characters the word has, 0 when the line is spent
;
; Spaces and tabs separate words, and nothing else does: the line feed that
; ended the line never reached the buffer.
parse_word:
        mov     rcx, [input_offset]
.skip_blanks:
        cmp     rcx, [input_length]
        jae     .line_is_spent
        mov     r9b, [input_buffer + rcx]
        cmp     r9b, ' '
        je      .blank
        cmp     r9b, 9                  ; a tab separates words like a space
        jne     .word_starts_here
.blank:
        inc     rcx
        jmp     .skip_blanks

.word_starts_here:
        mov     r8, rcx                 ; remember where, to measure it later
        lea     rax, [input_buffer + rcx]
.to_the_end:
        inc     rcx
        cmp     rcx, [input_length]
        jae     .word_ends_here
        mov     r9b, [input_buffer + rcx]
        cmp     r9b, ' '
        je      .word_ends_here
        cmp     r9b, 9
        jne     .to_the_end

.word_ends_here:
        mov     [input_offset], rcx     ; carry on from here next time
        sub     rcx, r8
        mov     rdx, rcx                ; how many characters the word has
        ret

.line_is_spent:
        mov     [input_offset], rcx
        xor     edx, edx
        ret

        section .text

; to_number turns text into a number. It takes the address of the text in rdi
; and its length in rsi, and leaves the value in rax with 1 in rdx. When the
; text is not a number it leaves 0 in rdx.
;
;   in    rdi   where the text starts
;         rsi   how many characters it has
;   out   rax   the value the text spells, or 0 when it spells no number
;         rdx   1 when the text was a number, 0 when it was not
;
; Two return registers rather than a value that doubles as its own error: 0 is
; a perfectly good number, so the answer cannot say whether it is one.
;
; Decimal only: mforth has no BASE. A minus sign may come first, but a minus
; sign on its own is not a number, which is what leaves - free to be the name
; of the subtraction word.
to_number:
        xor     eax, eax                ; the number built so far
        xor     r8d, r8d                ; 1 once a minus sign has been seen
        test    rsi, rsi
        jz      .not_a_number           ; nothing at all is not a number
        cmp     byte [rdi], '-'
        jne     .next_digit
        mov     r8d, 1
        inc     rdi                     ; step over the sign
        dec     rsi
        jz      .not_a_number           ; a minus sign and nothing after it

.next_digit:
        movzx   rcx, byte [rdi]
        cmp     rcx, '0'
        jb      .not_a_number           ; anything but a digit makes it a word
        cmp     rcx, '9'
        ja      .not_a_number
        sub     rcx, '0'                ; the digit the character stands for
        imul    rax, rax, 10            ; make room for it on the right
        add     rax, rcx
        inc     rdi
        dec     rsi
        jnz     .next_digit

        test    r8d, r8d
        jz      .a_number
        neg     rax                     ; the minus sign at the front
.a_number:
        mov     edx, 1
        ret

.not_a_number:
        xor     eax, eax
        xor     edx, edx
        ret

; KEY ( -- c ) leaves the next character of the line, or the line feed that
; ended it once the line is spent.
;
; The outer interpreter does not use KEY: it reads whole words through
; parse_word. KEY is here because a Forth has it, and because it shows what the
; interpreter is reading from. It never asks for a new line, so typing it
; cannot swallow the line the person is about to type.
        defcode "KEY", key
        mov     rcx, [input_offset]
        cmp     rcx, [input_length]
        jae     .line_is_spent
        movzx   rax, byte [input_buffer + rcx]
        inc     rcx
        mov     [input_offset], rcx
        jmp     .push_it
.line_is_spent:
        mov     eax, 10                 ; the line feed refill did not store
.push_it:
        sub     DSP, 8
        mov     [DSP], rax
        NEXT

; WORD ( -- c-addr u ) leaves the next word of the line: where its characters
; start, and how many of them there are. u is 0 when the line is spent.
;
; The characters stay in the input buffer. Nothing copies them, so what WORD
; leaves is good only until the next line is read.
        defcode "WORD", word
        call    parse_word
        sub     DSP, 8
        mov     [DSP], rax              ; where the characters start
        sub     DSP, 8
        mov     [DSP], rdx              ; how many there are
        NEXT

; \ ( -- ) ends the line. Immediate.
;
; The rest of what was typed is a comment, so this word spends the line by
; moving the place parse_word reads from to the end of it. INTERPRET asks for
; the next word, gets nothing, and reads a new line.
;
; It has to be immediate: a comment inside a definition is read while ":" is
; compiling, and a word that is not immediate would be appended to the body
; instead of running.
        defcode "\", backslash, F_IMMEDIATE
        mov     rax, [input_length]
        mov     [input_offset], rax
        NEXT

; ( ( -- ) ends the comment at the next ")". Immediate.
;
; This is the stack-effect comment every definition in lib/prelude.f carries,
; and it is a word like any other: the space after it is what makes the line
; "( n -- -n )" three words the interpreter never sees rather than punctuation
; the parser knows about.
;
; A comment that reaches the end of the line without a ")" ends there. mforth
; keeps one line at a time, so there is no next line for it to run into.
        defcode "(", paren, F_IMMEDIATE
        mov     rcx, [input_offset]
.look_for_the_bracket:
        cmp     rcx, [input_length]
        jae     .the_line_ended_first
        mov     al, [input_buffer + rcx]
        inc     rcx
        cmp     al, ')'
        jne     .look_for_the_bracket
.the_line_ended_first:
        mov     [input_offset], rcx     ; carry on after the comment
        NEXT

; ['] ( -- ) compiles the execution token of the word named after it.
; Immediate.
;
; A definition that compiles another word has to name it, and a token is an
; address nobody can type. A number typed inside a definition becomes a LIT
; cell and the value after it; this word lays down that same pair, with the
; token of the name it reads as the value. So ['] 0BRANCH inside a definition
; means "push the token of 0BRANCH when this word runs", which is what lets
; lib/prelude.f define IF.
;
; It is immediate, so it runs while the definition around it is being built.
; The name it reads is taken from the input at that moment, with parse_word,
; the way ":" takes the name of the word being defined.
;
; The standard's ' is the same lookup for a word being interpreted rather than
; compiled, and the brackets are how Forth spells "do it now". mforth has no '
; because nothing needs one yet.
;
; A name no word has leaves 0 and compiles LIT 0. Nothing reports it, the same
; answer the two stacks and the dictionary region give.
        defcode "[']", bracket_tick, F_IMMEDIATE
        call    parse_word              ; rax is where it starts, rdx how long
        mov     rdi, rax
        mov     rsi, rdx
        call    find_name               ; the execution token, or 0
        mov     r8, rax                 ; it has to outlive the call below
        mov     rdi, xt_lit
        call    comma_cell
        mov     rdi, r8
        call    comma_cell              ; the token itself, as LIT's value
        NEXT

; NUMBER ( c-addr u -- n f ) turns text into a number. f is 1 when the text was
; one, and 0 when it was not, in which case n is 0.
;
; The standard spells this >NUMBER and has it convert as far as it can, leaving
; the rest. mforth answers yes or no about the whole text, because that is the
; only question the interpreter asks.
        defcode "NUMBER", number
        mov     rdi, [DSP + 8]          ; where the characters start
        mov     rsi, [DSP]              ; how many there are
        call    to_number
        mov     [DSP + 8], rax          ; the value goes where c-addr was
        mov     [DSP], rdx              ; and the flag where u was
        NEXT

; INTERPRET ( -- ) handles one word of input, then comes back for the next.
;
; The first instruction is what makes this a loop. NEXT stepped IP past the one
; cell of the thread above, and pointing IP back at that cell means the next
; NEXT to run, wherever it runs, reads xt_interpret again. The word this one
; jumps into ends with its own NEXT and so returns here without knowing where
; it was called from. A word written in Forth returns the same way, because
; docol saves IP and EXIT puts it back.
;
; The dictionary is asked before the number is attempted. That order is what
; makes - the subtraction word rather than a number that failed to convert.
;
; A standard Forth empties the data stack when it reports an unknown word.
; mforth leaves it alone: what is on the stack is what the person put there.
        defcode "INTERPRET", interpret
        mov     IP, interpreter         ; come back here when that word ends
        call    parse_word              ; rax is where it starts, rdx how long
        test    rdx, rdx
        jz      .line_is_done
        mov     [word_address], rax     ; the unknown path needs them again
        mov     [word_length], rdx
        mov     rdi, rax
        mov     rsi, rdx
        call    find_name               ; the execution token, or 0
        test    rax, rax
        jnz     .run_the_word
        mov     rdi, [word_address]
        mov     rsi, [word_length]
        call    to_number
        test    rdx, rdx
        jz      .unknown_word
        cmp     qword [state], 0
        jne     .compile_a_literal
        sub     DSP, 8                  ; push what the text spelled
        mov     [DSP], rax
        NEXT

; A word of that name exists. Run it when the interpreter is running what it
; reads, and run it anyway when it is immediate. Otherwise append its token to
; the definition being built, which is the whole of what compiling a word is.
.run_the_word:
        cmp     qword [state], 0
        je      .execute_it
        test    qword [rax - 8], F_IMMEDIATE  ; the flags of the word found
        jnz     .execute_it
        mov     rdi, rax
        call    comma_cell              ; append the token to the body
        NEXT

; Jump through the word's code field, which is what NEXT does with a token it
; reads from a thread. This one came off the input instead, and that is the
; only difference between here and EXECUTE.
.execute_it:
        mov     W, rax
        jmp     [W]

; Compiling, and the text spells a number. A number in a body takes two cells:
; LIT, which pushes the cell after itself, and then the number. The diagram
; above ":" in src/compiler.asm shows the pair sitting in a finished word.
.compile_a_literal:
        mov     r8, rax                 ; the value has to outlive the call
        mov     rdi, xt_lit
        call    comma_cell
        mov     rdi, r8
        call    comma_cell
        NEXT

; The line is spent. Answer it the way a Forth answers, and read the next.
.line_is_done:
        mov     rdi, ok_message
        call    puts
        jmp     .read_a_line

; Neither a word nor a number. Name it back and read the next line, which
; drops whatever else was typed on this one.
;
; Compiling stops here too, so the next line is run and not appended to a
; definition that will never be finished. That definition is left where it is:
; still hidden, still the newest word, and its space in the dictionary spent.
; Nothing rolls it back, which is the answer the two stacks and the input
; buffer already give.
.unknown_word:
        mov     qword [state], 0
        mov     rdi, unknown_format
        mov     esi, [word_length]      ; %.*s wants the length as an int
        mov     rdx, [word_address]
        xor     eax, eax                ; printf is variadic: no vector args
        call    printf

.read_a_line:
        call    refill
        test    rax, rax
        jz      code_bye                ; the input ran out: leave through BYE
        NEXT
