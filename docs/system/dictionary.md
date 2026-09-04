# Dictionary

Every word in mforth carries its name. The names are chained into one list, and FIND walks
that list to turn a name into an execution token.

## What a word looks like in memory

A word is a header followed by a code field. The execution token is the address of the code
field, which is what it was before headers existed.

| Offset from the header | Size | Field |
|------------------------|------|-------|
| 0 | 8 | Link: the address of the header of the word defined before this one. 0 in the first word defined. |
| 8 | 1 | Name length in bytes. |
| 9 | the name length | The characters of the name. |
| after the name | 0 to 7 | Zero padding, up to the next multiple of 8. |
| | 8 | Flags. Every word holds 0 here. |
| | 8 | Code field. The execution token points at this cell. |

The flags sit after the name and not before it. A name is as long as it is, so no field after
the name starts at a fixed distance from the header. The flags are always the cell before the
code field, so a word's flags can be read as `[xt - 8]` from its execution token alone.
`F_IMMEDIATE` and `F_HIDDEN` are declared in `include/dictionary.inc`; ticket 006 is the first
code that sets or reads them.

The macro pads with `align 8, db 0`. A plain `align 8` fills the gap with 0x90 bytes instead,
which then sit between the name and the flags in any dump of a header.

## Defining a word

`include/dictionary.inc` holds two macros. Both lay down a header and a code field, and they
differ in what the code field holds.

| Macro | Defines | Code field | Where the macro leaves the assembler |
|-------|---------|-----------|--------------------------------------|
| `defcode "DUP", dup` | A word written in assembly | `code_dup`, the label the macro writes | `.text`, so the machine code follows the call |
| `defword "PRINT42", print42` | A word written in Forth | `docol` | `.data`, so the execution tokens follow the call |

A call carries all three cases at once: `defcode "DUP", dup`. The macro is lowercase because
it is assemble-time machinery, like `db` or `align`; `"DUP"` is uppercase because it is the
name a programmer types at DUP; `dup` is lowercase because it is the stem of the labels the
macro writes, `header_dup`, `xt_dup` and `code_dup`. The rule is in
`docs/system/inner-interpreter.md`.

Each macro redefines `PREVIOUS_HEADER`, a nasm `%define`, to the header it just laid down. The
next header links back to it. This is why the order words appear in the source is the order
they are chained in.

`latest` is a cell in `src/mforth.asm` holding the address of the last header defined, which is
PRINT42's. It is written in that file and not in `src/words.asm` because PRINT42 is defined
after every word in `src/words.asm`, and a walk that starts anywhere earlier cannot reach it.

A word defined after that cell is still chained: its link points back at the word before it.
No walk reaches it, though, because every walk starts at `latest`. Nothing reports this. The
source assembles, the binary links, and FIND returns 0 for a name that is in the dictionary.
A new word goes before the `latest` cell, not after it.

## FIND

`FIND ( c-addr u -- xt )` takes the address of a name and its length, and leaves the execution
token of the word with that name, or 0. It starts at `latest` and follows the links back. For
each word it compares the length first and calls libc `memcmp` only when the lengths match.
The comparison is case-sensitive: `DUP` finds DUP and `dup` finds nothing.

FIND holds the header it is looking at in r14, which the ABI makes libc give back untouched,
and no other code in mforth uses. Both arguments stay on the data stack while the walk runs,
so the call to `memcmp` needs nothing saved around it.

The Forth 2012 standard defines `FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )`: it takes a
counted string and leaves a flag saying whether the word is immediate. mforth takes an address
and a length, and leaves no flag, because the flags of a word are readable at `[xt - 8]`.

`EXECUTE ( xt -- )` takes an execution token off the data stack and jumps through its code
field. It is NEXT's last instruction with the token taken from the stack instead of the thread.

## What is not here yet

Nothing builds a header while the program runs. HERE, ALLOT and CREATE arrive with ticket 006,
and until then every header is assembled by one of the two macros. `latest` is a fixed cell,
not a variable the compiler updates.
