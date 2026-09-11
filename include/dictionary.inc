; What a dictionary entry is made of, and the two macros that lay one down.
;
; A Forth looks its words up by name while it runs, so every word has to
; carry its name with it. The name, a link to the word defined before it, and
; a cell of flags make up the header. The code field follows the header, and
; a word's execution token is the address of that code field, exactly as it
; was before this file existed.
;
; The flags sit after the name rather than before it. A name is as long as it
; is, so nothing after the name starts at a fixed distance from the header.
; The cell in front of the code field, though, is always the flags, which is
; how INTERPRET asks whether a word is immediate when all it holds is an
; execution token: the flags are at [xt - 8].
;
; The macros below lay a header down while the assembler runs. create_header
; in src/compiler.asm lays down the same five fields in the same order while
; mforth runs. Both write the layout drawn below, and they are the only two
; places that write it.

; The link of the first word defined holds 0, because there is no word before
; it. Every header laid down redefines this to itself, so the next word links
; back to it and the words end up chained newest first.
%define PREVIOUS_HEADER 0

; The flags. A word marked F_IMMEDIATE runs even while the interpreter is
; compiling, which is how ";" ends a definition it would otherwise be part of.
; A word marked F_HIDDEN is skipped by FIND, which is how ":" keeps a name
; meaning the older word until the definition under it is finished.
;
; The third argument of the macros below writes them at assembly time. At
; runtime the compiler writes the same cell: see create_header in
; src/compiler.asm.
F_IMMEDIATE     equ 1
F_HIDDEN        equ 2

; header lays down the part every word has in common. The two macros below
; add the code field, which is the part that differs. This is the header of
; DUP, one row to a cell:
;
;                    section .data
;
;   header_dup -> +------------------+
;                 | link             |   the word defined before DUP
;                 | 3 D U P 0 0 0 0  |   the name: a length, then characters
;                 | flags = 0        |   always the cell before the code field
;   xt_dup ->     | code field       |   defcode or defword lays this down
;                 +------------------+
;
; The name is stored as a length byte followed by the characters themselves.
; FIND compares the length first and only looks at the characters when the
; lengths match, which is why the length comes first in memory too. The align
; writes the zeros that fill out the last cell of the name, so that the code
; field starts on a cell boundary: a thread is a list of addresses, and an
; address is a cell. DUP's length byte and characters come to four bytes, so
; four zeros follow them; EXECUTE's come to eight, and none do.
;
; The third argument is the flags, and it may be left off, which is why almost
; every word in mforth is defined with two. The words that pass F_IMMEDIATE
; are the ones that have to run while the compiler is compiling rather than be
; compiled into what it is building: ";", the two comment words, "[']", the
; words that build a loop, and the word that compiles text.
%macro header 2-3 0
        section .data
header_%2:
        dq      PREVIOUS_HEADER         ; the word defined before this one
        db      %%name_end - %%name_start
%%name_start:
        db      %1
%%name_end:
        align   8, db 0                 ; pad up to the next cell
        dq      %3                      ; flags
%define PREVIOUS_HEADER header_%2
%endmacro

; defcode defines a word written in assembly: a header, a code field holding
; the address of the machine code, and the machine code itself. The macro
; ends in .text with the label already written, so the instructions follow
; the call directly.
%macro defcode 2-3 0
        header  %1, %2, %3
xt_%2:
        dq      code_%2                 ; the code field: the machine code
        section .text
code_%2:
%endmacro

; defword defines a word written in Forth: a header, a code field holding
; docol, and then the execution tokens of the words to run. Those tokens are
; cells of data, so this macro leaves the assembler in .data, where the body
; of such a word belongs.
;
; Nothing calls it. It sits here beside defcode because the two together are
; the whole answer to what kinds of word there are, and it is the assemble-time
; statement of the second kind. Every word of that kind is built by ":" while
; mforth runs, out of what a person types.
%macro defword 2-3 0
        header  %1, %2, %3
xt_%2:
        dq      docol                   ; the code field: enter a Forth word
%endmacro
