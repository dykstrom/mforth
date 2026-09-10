# The compiler

`src/compiler.asm`: the words that add to the dictionary while mforth runs. Before this
iteration every dictionary entry was laid down by the `header` macro before the program
started. Now a person types `: SQUARE DUP * ;` and the word exists.

## Where a compiled word lives

`dictionary_space` is a `DICTIONARY_SIZE`-byte `.bss` region in `src/compiler.asm`.
`DICTIONARY_SIZE` is 65536 and is declared in `include/mforth.inc` beside the two stack sizes
and the input buffer size. Nothing checks the region for overflow, the same answer the two
stacks give.

A word defined at runtime has its header first and its body after it, and the next word
defined follows that. Two cells in `.data` hold the state of the compiler:

| Cell | Holds |
|------|-------|
| `here` | The address of the next free byte. Starts at `dictionary_space`. |
| `state` | 0 while the interpreter runs the words it reads, -1 while it compiles them. Starts at 0. |
| `latest` | The newest header, where every walk of the dictionary starts. `main` stores the starting value. |

`here` and `state` are initialised where they are declared. The binary is linked with
`-no-pie`, which makes `dictionary_space` a number the linker knows.

`latest` cannot be. Its starting value is `PREVIOUS_HEADER`, the nasm `%define` that each
header redefines to itself, and at this point in the source the assembler has reached only the
compiler's own words: the interpreter in `src/outer.asm` is not defined yet. `main` stores it
instead, because `main` is the only code that comes after every `%include`.
`docs/system/dictionary.md` covers the chain.

The chain of headers crosses from `.bss` back into `.data`. `create_header` writes whatever
`latest` holds into the new header's link cell, so the first word a person defines links back
to INTERPRET, the last word the assembler laid down. `find_name` walks across the join without
knowing it is there.

## The three subroutines

`FIND` is a wrapper around the subroutine `find_name`, and `INTERPRET` calls that subroutine
directly. The compiler is built the same way: the work is a plain assembly subroutine taking
its arguments in the registers the C library would use, and the Forth word is a wrapper that
moves cells between the data stack and those registers.

| Subroutine | In | Out |
|-----------|----|-----|
| `header_flags` | `rdi` a header address | `rax` the address of that header's flags cell |
| `create_header` | `rdi` where the name starts, `rsi` how many characters | The header is in the dictionary and HERE is at the code field |
| `comma_cell` | `rdi` the cell to store | The cell sits at the old HERE, and HERE has moved on eight |

`header_flags` is the arithmetic that steps over a name and rounds up to the next cell.
`docs/adr/0004-flags-after-the-name-in-a-header.md` recorded that this arithmetic would end up
in three places: the `header` macro, `FIND`, and `CREATE`. It is in two. `create_header`,
`find_name`, `:` and `;` all call this subroutine, and the `align 8, db 0` in the macro is the
only other place that rounds a name up.

`header_flags` calls nothing and touches nothing but `rax`, which is what lets `find_name`
call it in the middle of a walk that holds live values in `r14`, `r15` and `rbp`.

`create_header` writes the five fields the macro writes, in the same order: the link, the
length byte, the characters, the padding, and the flags. It also stores the new header's
address in `latest`. It leaves the flags 0; a caller that wants one set writes it afterwards.
It does not write the padding bytes at all, because the region is `.bss` and starts as zeros,
and nothing reads them: `FIND` compares as many characters as the length byte says. It calls
`header_flags` to find where the flags cell goes, which it can do once the length byte is
written, because that byte is all `header_flags` reads.

`comma_cell` is called from six places: the word `,`, the words `:` and `;`, the branch of
`INTERPRET` that appends a token, and twice in the branch that compiles a number. It touches
`rax` and `rdi` only, and that number branch relies on it: it keeps the value in `r8` across
the first call.

## The words

| Word | Stack effect | What it does |
|------|-------------|--------------|
| `HERE` | `( -- addr )` | Leaves the address of the next free byte. |
| `ALLOT` | `( n -- )` | Reserves n bytes. A negative n gives space back. |
| `,` | `( n -- )` | Stores n at HERE and steps HERE past it. |
| `C,` | `( c -- )` | Stores the low byte of c at HERE and steps HERE past it. |
| `STATE` | `( -- addr )` | Leaves the address of the `state` cell. |
| `CREATE` | `( c-addr u -- )` | Lays down the header of a word of that name. |
| `:` | `( -- )` | Starts a definition. |
| `;` | `( -- )` | Ends a definition. Immediate. |

`HERE` leaves the value of its cell and `STATE` leaves the address of its cell. That asymmetry
is the standard's. `STATE @` is how a program reads the state, using the `@` from ticket 005.

`state` holds -1 for compiling because -1 is the true the comparison words leave, which
`docs/system/core-words.md` describes.

`CREATE` deviates from the standard twice. The standard's `CREATE` parses its own name out of
the input, and gives the new word a code field that pushes the address of its body. mforth's
takes the name off the stack, the way `FIND` does, and lays the header and nothing else.
`WORD CREATE` is the standard's spelling of it. Leaving the code field empty is what `:` needs,
because `:` writes `docol` there. See
`docs/adr/0007-create-takes-its-name-from-the-stack.md`.

## What `:` and `;` do

`:` takes the next word of the line as the name, calls `create_header`, sets `F_HIDDEN` on the
new header, writes `docol` into the code field with `comma_cell`, and stores -1 in `state`.

`;` compiles `xt_exit`, clears the flags cell on `latest`, and stores 0 in `state`. It is the
one word in mforth defined with `F_IMMEDIATE`, through the third argument of `defcode`:

```
        defcode ";", semicolon, F_IMMEDIATE
```

`;` has to be immediate. Every other word on the line is appended to the body, and if `;` were
appended too then nothing would end the definition.

`EXIT` is compiled before the hidden flag is cleared, so the name does not become findable
until the body behind it is complete.

Neither word checks anything. `: ;` defines a word with no name, which no name then reaches. A
`:` while a definition is already open starts a second one and abandons the first.

## Hiding

`find_name` passes over a header whose flags carry `F_HIDDEN`, as though the name had not
matched, and carries on to the word defined before it. Inside a definition the name being
defined therefore still means the word it replaces:

```
: FOO 1 ;
: FOO FOO 1 + ;
FOO .
```

prints 2. The `FOO` in the second definition compiled the token of the first.

## Compiling a definition that spans lines

`state` is a cell, not something a line owns, so it survives `refill`. A definition may be
typed over several lines, and `INTERPRET` answers ` ok` at the end of each one whether it is
compiling or not, which is what other Forths print.

## Testing

`tests/colon-definitions.f` holds one behaviour per line and its output is diffed against
`tests/colon-definitions.expected`.

| Input | Prints | Covers |
|-------|--------|--------|
| `: SQUARE DUP * ;` then `7 SQUARE .` | `49` | A definition compiled and run |
| `: CUBE DUP SQUARE * ;` then `3 CUBE .` | `27` | A definition naming one compiled before it |
| `: FOURTH` then `SQUARE SQUARE ;` then `2 FOURTH .` | `16` | A definition spanning two lines |
| `: LUCKY 7 ;` then `LUCKY .` | `7` | A number compiled as `LIT` and a cell |
| `: FOO 1 ;` then `: FOO FOO 1 + ;` then `FOO .` | `2` | `F_HIDDEN` |
| `STATE @ .` | `0` | `STATE` leaves an address |
| `HERE 8 ALLOT DUP 42 SWAP ! @ .` | `42` | `HERE` and `ALLOT` hand out usable space |
| `HERE 11 , @ .` | `11` | `,` |
| `HERE 65 C, C@ .` | `65` | `C,` |
| `: BAD DUP QQQ * ;` then `1 2 + .` | `QQQ ?` then `3` | The unknown word puts `state` back to 0 |

Trailing spaces are significant in the expected file: `.` prints a space after the number and
` ok` begins with one.
