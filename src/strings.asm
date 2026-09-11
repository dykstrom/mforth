; The words that exist for the person watching: text on the terminal, and two
; ways of asking mforth what it is holding.
;
; Everything before this file prints numbers. "." turns a cell into digits and
; CR ends the line, and between them there is no way to print a word of
; English. The six words here are the ones a demonstration needs, and ." is the
; interesting one: it puts the text it prints inside the definition that prints
; it.
;
; A string in Forth is a length and the characters, not characters and a zero
; at the end. print_text below is the one place that turns such a pair into
; output, and TYPE, (.") and WORDS all reach the terminal through it.

        section .text

; print_text prints a string given as an address and a length.
;
;   in    rdi   where the characters are
;         rsi   how many of them there are
;   out   none
;
; This is an ordinary assembly subroutine, the way find_name is, not a Forth
; word. printf's "%.*s" prints exactly as many characters as it is told to,
; which is what a string with a length needs: nothing in mforth is terminated
; by a zero byte. The length goes in printf's second argument and only its low
; half is read, because the "*" stands for an int.
;
; The last instruction is a jump and not a call. The return address the caller
; pushed is still at the top of the stack, so printf returns straight to the
; caller, and the stack is aligned exactly as the ABI wants it at a call.
print_text:
        mov     rdx, rdi                ; the characters are printf's third
        mov     rdi, text_format
        xor     eax, eax                ; printf is variadic: no vector args
        jmp     printf

; EMIT ( c -- ) prints one character.
;
; This is CR with the character taken from the stack instead of being the line
; feed every time. putchar takes an int, so only the low half of the cell is
; read, and a c larger than a byte loses its top without a word about it.
        defcode "EMIT", emit
        mov     rdi, [DSP]              ; the character to print
        add     DSP, 8
        call    putchar
        NEXT

; TYPE ( c-addr u -- ) prints u characters starting at c-addr.
;
; c-addr u is how Forth writes a string on the stack, and it is what WORD
; leaves, which is the easiest way to hand this word something to print.
        defcode "TYPE", type
        mov     rdi, [DSP + 8]          ; where the characters are
        mov     rsi, [DSP]              ; how many there are
        add     DSP, 16                 ; both items are gone
        call    print_text
        NEXT

; ." ( -- ) compiles the text up to the closing quote into the definition being
; built. Immediate.
;
; The text has to live somewhere, and in threaded code there is nowhere to put
; it but the thread itself. That is the answer LIT already gives for a number,
; and this is the same answer for a string. ." appends the token of (.") and
; then lays the text down straight after it, as a length byte and the
; characters, padded out to a cell so that the token after the text lands on a
; cell boundary. The body of : GREET ." hi" CR ; ends up like this:
;
;                 +--------------------+
;                 | xt_paren_dot_quote |
;                 | 2 h i 0 0 0 0 0    |   the text, padded to one cell
;                 | xt_cr              |
;                 | xt_exit            |
;                 +--------------------+
;
; The one space after ." is the delimiter and is not part of the text, which
; is why a second space would be. The text ends at the closing quote, or at
; the end of the line when there is none: mforth keeps one line at a time, so
; there is no next line for it to run into.
;
; It has to be immediate, like every other word that compiles something. Typed
; outside a definition it lays the same cells down where nothing will ever run
; them, and prints nothing. Nothing reports that, which is the answer the two
; stacks and the dictionary region already give.
;
; The name is written in single quotes because nasm does not read a backslash
; inside a double-quoted string, so there is no way to put a quote in one.
        defcode '."', dot_quote, F_IMMEDIATE
        mov     rdi, xt_paren_dot_quote
        call    comma_cell              ; the word that does the printing

        mov     rcx, [input_offset]
        cmp     rcx, [input_length]
        jae     .copy_the_text          ; nothing follows the word at all
        cmp     byte [input_buffer + rcx], ' '
        jne     .copy_the_text
        inc     rcx                     ; the one space after ." is the delimiter

.copy_the_text:
        mov     rdx, [here]             ; the length byte goes here
        lea     r8, [rdx + 1]           ; and the characters after it
.next_char:
        cmp     rcx, [input_length]
        jae     .the_text_is_done       ; the line ended before the quote did
        mov     al, [input_buffer + rcx]
        inc     rcx
        cmp     al, '"'
        je      .the_text_is_done
        mov     [r8], al
        inc     r8
        jmp     .next_char

.the_text_is_done:
        mov     [input_offset], rcx     ; carry on after the closing quote
        lea     rax, [rdx + 1]          ; where the characters started
        sub     r8, rax                 ; so this is how many there are
        mov     [rdx], r8b              ; the length byte, in front of them
; The text takes the length byte and the characters, and HERE has to end up on
; a cell boundary for the token that follows. Adding 8 to the count covers the
; length byte and rounds up at once, and clearing the low three bits is what
; rounds it.
        lea     rax, [r8 + 8]
        and     rax, -8
        add     rdx, rax
        mov     [here], rdx
        NEXT

; (.") ( -- ) prints the text that follows it in the thread.
;
; This is the word ." compiles, and it is LIT one step further: LIT reads one
; cell out of the thread and steps IP over it, and this reads a length byte
; and that many characters and steps IP over all of them, rounded up to the
; cell the next token starts on.
;
; A Forth normally keeps this word out of reach, because typing it where there
; is no thread to read from makes no sense. mforth gives it a name for the same
; reason LIT has one: every word in the dictionary is there to be looked at.
        defcode '(.")', paren_dot_quote
        movzx   rsi, byte [IP]          ; how many characters there are
        lea     rdi, [IP + 1]           ; and where they start
        lea     rax, [rsi + 8]          ; the length byte, and 7 to round up
        and     rax, -8
        add     IP, rax                 ; step over the text to the next token
        call    print_text              ; printf gives IP back untouched
        NEXT

; .S ( -- ) prints the data stack without changing it.
;
; The depth comes first, in angle brackets, so that an empty stack prints
; "<0> " and not nothing at all. Then the items, the one pushed first at the
; left, each followed by a space the way "." leaves one.
;
; This word is assembly because it reads the stack itself, and no word written
; in Forth can: the stack is where a word's arguments are, not somewhere it can
; walk. The subtraction is DEPTH's, in src/words.asm.
;
; The walk keeps its place in r14. printf may use any of the caller-saved
; registers, and r14 is one of the three that find_name explains are free.
        defcode ".S", dot_s
        mov     rax, data_stack_top
        sub     rax, DSP                ; how many bytes are in use
        shr     rax, 3                  ; eight bytes to a cell
        mov     rsi, rax                ; how many items there are
        mov     rdi, depth_format
        xor     eax, eax                ; printf is variadic: no vector args
        call    printf

        mov     r14, data_stack_top
        sub     r14, 8                  ; the item that was pushed first
.this_item:
        cmp     r14, DSP                ; DSP is the item pushed last
        jb      .the_stack_is_done
        mov     rsi, [r14]
        mov     rdi, dot_format         ; the number and a space, as "." prints
        xor     eax, eax
        call    printf
        sub     r14, 8                  ; the item pushed after it
        jmp     .this_item

.the_stack_is_done:
        NEXT

; WORDS ( -- ) prints the name of every word in the dictionary.
;
; This is find_name's walk with the comparing taken out. It starts at latest
; and follows each header's link back to the word defined before it, so the
; newest name is printed first and the oldest last. The words a person has
; defined come first, then the twelve lib/prelude.f defines, then the assembly
; words in the order the %includes laid them down.
;
; A hidden word is printed too. The only hidden word is one a definition that
; failed left behind, and this is the word that shows it is there.
        defcode "WORDS", words
        mov     r14, [latest]           ; the newest word in the dictionary
.this_word:
        test    r14, r14                ; 0 is the link of the first word
        jz      .the_dictionary_is_done
        movzx   rsi, byte [r14 + 8]     ; how long this word's name is
        lea     rdi, [r14 + 9]          ; its characters, after the length
        call    print_text
        mov     edi, ' '                ; one space between two names
        call    putchar
        mov     r14, [r14]              ; the word defined before this one
        jmp     .this_word

.the_dictionary_is_done:
        mov     edi, 10                 ; the ASCII line feed, as CR sends
        call    putchar
        NEXT

        section .rodata

; The "*" takes the length from the argument before the string, so printf
; prints that many characters and stops. Without it printf would read on until
; it found a zero byte, and a name in the dictionary has none after it.
text_format:
        db      "%.*s", 0

; The depth, in front of the items .S prints.
depth_format:
        db      "<%ld> ", 0
