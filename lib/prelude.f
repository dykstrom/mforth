\ The part of mforth that is written in Forth.
\ Every word here is built from words that are already there, which is the
\ whole claim Forth makes about itself. Each definition uses only the words
\ defined above it.

\ The conditional, written in Forth.
\
\ IF, ELSE and THEN are not syntax. Each one is a word that runs while the
\ compiler is compiling, and each does nothing but lay cells down and fill in
\ cells laid down earlier. Three words do the laying: ['] leaves the execution
\ token of the name after it, "," puts a cell at HERE, and IMMEDIATE marks the
\ finished word so that ":" runs it instead of compiling it.
\
\ 0BRANCH and BRANCH stay in src/control.asm. They move IP, and only assembly
\ can do that. See docs/adr/0009-control-structures-in-the-prelude.md.

: IF                    ( -- hole )
    ['] 0BRANCH ,       \ compile the jump: 0BRANCH takes it when the flag is 0
    HERE                \ where the cell holding that jump's target goes
    0 ,                 \ lay it down empty - nobody knows the target yet
;                       \ and leave its address for THEN or ELSE to fill in
IMMEDIATE

: ELSE                  ( hole1 -- hole2 )
    ['] BRANCH ,        \ the true part ends by jumping over the false part
    HERE                \ where that jump's target cell goes
    0 ,                 \ empty too - THEN fills this one in
    SWAP                \ hole2 underneath, hole1 back on top
    HERE SWAP !         \ IF's jump lands here, after the two cells above
;                       \ leaving hole2, so THEN sees one hole either way
IMMEDIATE

: THEN                  ( hole -- )
    HERE SWAP !         \ the jump that left the hole lands where we stand
;                       \ THEN compiles nothing: the whole cost is one 0BRANCH
IMMEDIATE

: 0=      ( n -- flag )         0 = ;                \ 0 is the only false
: 0<      ( n -- flag )         0 < ;                \ signed, like < itself
: 1+      ( n -- n+1 )          1 + ;                \ the commonest addition
: 1-      ( n -- n-1 )          1 - ;                \ and the commonest one
: 2*      ( n -- n*2 )          2 * ;                \ a shift in other Forths
: NIP     ( n1 n2 -- n2 )       SWAP DROP ;          \ drop the one underneath
: TUCK    ( n1 n2 -- n2 n1 n2 ) SWAP OVER ;          \ a copy of n2 below n1
: ?DUP    ( n -- n n | 0 )      DUP IF DUP THEN ;    \ copy it unless it is 0
: NEGATE  ( n -- -n )           0 SWAP - ;           \ 0 - n is -n
: ABS     ( n -- |n| )          DUP 0< IF NEGATE THEN ;
: /       ( n1 n2 -- quot )     /MOD NIP ;           \ /MOD leaves rem under quot
: MOD     ( n1 n2 -- rem )      /MOD DROP ;          \ and the quotient on top
: SPACE   ( -- )                32 EMIT ;            \ one blank, ASCII 32
