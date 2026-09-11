65 EMIT CR
WORD Forth TYPE CR
: GREET ." Hello, Forth!" CR ;
GREET
1 2 3 .S CR
+ + . CR
.S CR
65 EMIT SPACE 66 EMIT CR
." not printed"
WORDS
