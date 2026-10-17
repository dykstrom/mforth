; phase2.asm - puzzle D2: the input phase 2 accepts.
;
;     int phase2(const char *input);
;
; phase2 is in the puzzle, which has no source here. The test hands it the
; string below and passes if it returns 1. Find out what it wants with
; ./debug d2, and write that between the quotes.

        global  input

        section .rodata
input:  db      "", 0                   ; TODO: what phase2 wants
