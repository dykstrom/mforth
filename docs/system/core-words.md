# Core words

The vocabulary in `src/words.asm`: the words that have to be written in assembly, because
they touch the stacks, the machine's arithmetic, or memory directly. Every one is a `defcode`
definition — a header, a code field holding the address of machine code, and the machine code
itself — so a reader sees the same shape 30 times.

The words KEY, WORD, NUMBER and INTERPRET are also `defcode` definitions, but they live in
`src/outer.asm` with the interpreter machinery they belong to. See
`docs/system/outer-interpreter.md`.

## The words

| Group | Word | Stack effect |
|-------|------|--------------|
| Literal | `LIT` | `( -- n )` |
| Stack | `DUP` | `( n -- n n )` |
| | `DROP` | `( n -- )` |
| | `SWAP` | `( n1 n2 -- n2 n1 )` |
| | `OVER` | `( n1 n2 -- n1 n2 n1 )` |
| | `ROT` | `( n1 n2 n3 -- n2 n3 n1 )` |
| | `DEPTH` | `( -- n )` |
| Arithmetic | `+` | `( n1 n2 -- n3 )` |
| | `-` | `( n1 n2 -- n3 )` |
| | `*` | `( n1 n2 -- n3 )` |
| | `/MOD` | `( n1 n2 -- rem quot )` |
| Comparison | `=` | `( n1 n2 -- flag )` |
| | `<` | `( n1 n2 -- flag )` |
| | `>` | `( n1 n2 -- flag )` |
| Logic | `AND` | `( n1 n2 -- n3 )` |
| | `OR` | `( n1 n2 -- n3 )` |
| | `XOR` | `( n1 n2 -- n3 )` |
| | `INVERT` | `( n1 -- n2 )` |
| Return stack | `>R` | `( n -- ) ( R: -- n )` |
| | `R>` | `( -- n ) ( R: n -- )` |
| | `R@` | `( -- n ) ( R: n -- n )` |
| Memory | `@` | `( addr -- n )` |
| | `!` | `( n addr -- )` |
| | `C@` | `( addr -- c )` |
| | `C!` | `( c addr -- )` |
| Output | `.` | `( n -- )` |
| | `CR` | `( -- )` |
| Dictionary | `FIND` | `( c-addr u -- xt )` |
| | `EXECUTE` | `( xt -- )` |
| Leaving | `BYE` | `( -- )` |

`.`, `CR` and `BYE` go through libc `printf`, `putchar` and `exit`. `FIND` and `EXECUTE` are
covered by `docs/system/dictionary.md`, `LIT` by `docs/system/inner-interpreter.md`.

## Flags

False is 0 and true is -1, every bit set. That is what lets `AND`, `OR` and `INVERT` serve as
the logical operations as well as the bitwise ones: `INVERT` turns true into false precisely
because -1 flips to 0. The three comparison words each zero a register, write 1 or 0 into its
low byte with `setcc`, and negate the whole of it to get the all-bits answer.

`<` and `>` use `setl` and `setg`, the signed comparisons. Every number on the stack is a
signed 64-bit cell; mforth has no unsigned words.

## Division

`/MOD` leaves both answers because division produces both and a stack can hold both. The
remainder goes underneath the quotient, so a caller can `DROP` the one it does not want.

`/MOD` rounds the quotient toward zero and leaves the remainder with the sign of the dividend,
so `-7 2 /MOD` leaves -1 and -3 — see `docs/adr/0006-division-rounds-toward-zero.md`. Divide by
zero raises SIGFPE and kills the process; nothing checks for it, in the same way nothing checks
either stack.

## The return stack words

`>R`, `R>` and `R@` are the only words a programmer types that touch the return stack. They
exist because the data stack cannot reach past its top few items: a value parked on the return
stack comes back untouched.

The return stack is also where `docol` left the address a word returns to. A definition that
pushes onto it and does not take the same number of cells back off before `EXIT` returns to
the wrong place. Nothing checks for that.

## Memory

An address is a number like any other and travels on the data stack. A cell is eight bytes:
`@` and `!` move a whole one, `C@` and `C!` move a single byte and leave the other seven
alone. `C@` widens with `movzx`, so a byte read back is never negative.

Nothing checks that an address is one mforth may touch, and nothing checks alignment.

`HERE` and `ALLOT` in `src/compiler.asm` hand out an address to use, so a program can reserve
space and read and write it with these four words. `docs/system/compiler.md` covers them. The
other addresses a program can reach are the ones `WORD` leaves, which point into the input
buffer.

## Words left out on purpose

`NEGATE`, `ABS`, `MOD`, `/`, `NIP`, `TUCK`, `?DUP`, `0=`, `0<`, `1+`, `1-` and `2*` can all be
built from the words above, so they are not here. Ticket 008 defines them in Forth, and that
they can be is the point that ticket makes. `VARIABLE` and `CONSTANT` are not here either;
`docs/system/compiler.md` lists what the compiler does define.

## Testing

`tests/core-words.f` exercises every word in the table that ticket 005 added, and
`tests/core-words.expected` holds the output. Trailing spaces matter: `.` prints a space after
the number and ` ok` begins with one, so a line reading `6  ok` holds two spaces.

The memory words are tested through `WORD`, because it is the only source of a usable address
in this iteration. `WORD XXXXXXXX DROP DUP 42 SWAP ! @ .` stores a cell over the eight
characters of `XXXXXXXX` in the input buffer and reads it back. Overwriting those characters
is safe because `parse_word` has already moved `input_offset` past them, so the eight bytes
written are text the interpreter is finished with. The name in the test is eight characters
long for that reason, and the `C!` line uses a one-character name for the same one.
