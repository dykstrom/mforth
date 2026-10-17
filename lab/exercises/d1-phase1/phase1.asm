; phase1.asm - puzzle D1: the input phase 1 accepts.
;
;     int phase1(const char *input);
;
; phase1 is in the puzzle, which has no source here. The test hands it the
; string below and passes if it returns 1. Find out what it wants with
; ./debug d1, and write that between the quotes.

        global  input

        section .rodata
input:  db      "", 0                   ; TODO: what phase1 wants
