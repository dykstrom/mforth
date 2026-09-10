# 0007. CREATE takes its name from the stack and writes no code field

*2026-09-10*

## Context

Forth 2012's `CREATE` does two things beyond laying down a header: it parses its own name out
of the input stream, and it writes a code field that pushes the address of the new word's
body. mforth has the pieces to do neither. `WORD` leaves an address and a length, and `FIND`
and `find_name` already take a name as exactly that pair. The only caller ticket 006 has is
`:`, which needs `docol` in the code field rather than an address-pushing one, so a `CREATE`
that wrote the standard's code field would have `:` overwrite it. Against that, `VARIABLE`,
`CONSTANT` and `DOES>` are built on `CREATE` in other Forths, and each would inherit the
standard's code field for free.

## Decision

We will define `CREATE ( c-addr u -- )`. It takes the name off the data stack, lays down the
link, the name, the padding and the flags, and stops with `HERE` at the code field, writing
nothing into it. `WORD CREATE` is how the standard's spelling is reached.

## Consequences

`CREATE` is the `create_header` subroutine and three lines that move two cells off the stack,
and it reads like `FIND` beside it: both take a name as an address and a length, so an
audience meets that pair once rather than twice. `:` writes `docol` with the same `,` a
program would use, which is worth showing. The costs are two deviations a reader who knows
another Forth will not expect, noted in the comment on `CREATE` and in
`docs/system/compiler.md`; and that every defining word added later writes its own code field,
so `VARIABLE` and `CONSTANT` will each be `CREATE` plus a cell. Ticket 006 puts those out of
scope, so nothing pays that cost yet.
