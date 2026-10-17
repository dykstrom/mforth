; upcase.asm - exercise A6: a string in capitals, changed where it lies.
;
;     void upcase(char *s);
;
; s, the address of the first character, arrives in rdi. Change every
; lowercase letter, a to z, into its capital, and leave every other byte as
; it is. The string ends at the first byte that is 0. Nothing is returned.

        global  upcase

        section .text
upcase:
        ; TODO: walk the string, and make each a to z a capital
        ret                             ; change nothing, for now
