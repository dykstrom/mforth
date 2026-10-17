; phase3.asm - puzzle D3: the input phase 3 accepts.
;
;     int phase3(const char *input);
;
; phase3 is in the puzzle, which has no source here. The test hands it the
; string below and passes if it returns 1. Find out what it wants with
; ./debug d3, and write that between the quotes.

        global  input

        section .rodata
input:  db      "", 0                   ; TODO: what phase3 wants
