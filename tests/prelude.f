0 0= . 1 0= .
-1 0< . 1 0< .
5 1+ . 5 1- . 5 2* .
1 2 NIP . 1 2 TUCK . . .
5 ?DUP . . 0 ?DUP .
7 NEGATE . -7 NEGATE .
-5 ABS . 5 ABS .
7 2 / . -7 2 / .
7 2 MOD . -7 2 MOD .
: SQUARE ( n -- n*n ) DUP * ;
5 SQUARE .
: TWICE ['] DUP , ['] + , ; IMMEDIATE
: DOUBLE ( n -- n*2 ) TWICE ;
21 DOUBLE .
