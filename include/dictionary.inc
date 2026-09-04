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
; how ticket 006 will ask whether a word is immediate when all it holds is an
; execution token.

; The link of the first word defined holds 0, because there is no word before
; it. Every header laid down redefines this to itself, so the next word links
; back to it and the words end up chained newest first.
%define PREVIOUS_HEADER 0

; The flags. Nothing sets either one in this iteration: ticket 006 is where
; they start to matter. They are named here because this is where the cell
; that holds them is laid down.
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
; four zeros follow them; PRINT42's come to eight, and none do.
%macro header 2
        section .data
header_%2:
        dq      PREVIOUS_HEADER         ; the word defined before this one
        db      %%name_end - %%name_start
%%name_start:
        db      %1
%%name_end:
        align   8, db 0                 ; pad up to the next cell
        dq      0                       ; flags
%define PREVIOUS_HEADER header_%2
%endmacro

; defcode defines a word written in assembly: a header, a code field holding
; the address of the machine code, and the machine code itself. The macro
; ends in .text with the label already written, so the instructions follow
; the call directly.
%macro defcode 2
        header  %1, %2
xt_%2:
        dq      code_%2                 ; the code field: the machine code
        section .text
code_%2:
%endmacro

; defword defines a word written in Forth: a header, a code field holding
; docol, and then the execution tokens of the words to run. Those tokens are
; cells of data, so this macro leaves the assembler in .data, where the body
; of such a word belongs.
%macro defword 2
        header  %1, %2
xt_%2:
        dq      docol                   ; the code field: enter a Forth word
%endmacro
