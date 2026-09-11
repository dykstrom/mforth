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
| | 8 | Flags. `F_IMMEDIATE` in a word that must run while the compiler is compiling, `F_HIDDEN` in a definition `:` has started and `;` has not finished, 0 in every other word. |
| | 8 | Code field. The execution token points at this cell. |

The flags sit after the name and not before it. A name is as long as it is, so no field after
the name starts at a fixed distance from the header. The flags are always the cell before the
code field, so a word's flags can be read as `[xt - 8]` from its execution token alone.
`F_IMMEDIATE` and `F_HIDDEN` are declared in `include/dictionary.inc`. `INTERPRET` reads
`F_IMMEDIATE` at `[xt - 8]` to decide whether to run a word while compiling. `find_name` reads
`F_HIDDEN` and passes over a word that carries it, which is how `:` keeps a name meaning the
older word until `;` finishes the new one.

The macro pads with `align 8, db 0`. A plain `align 8` fills the gap with 0x90 bytes instead,
which then sit between the name and the flags in any dump of a header. `create_header`, which
writes this layout at runtime, does not write the padding at all: its region is `.bss` and so
starts as zeros, and nothing reads those bytes.

## Defining a word

`include/dictionary.inc` holds two macros. Both lay down a header and a code field, and they
differ in what the code field holds.

| Macro | Defines | Code field | Where the macro leaves the assembler |
|-------|---------|-----------|--------------------------------------|
| `defcode "DUP", dup` | A word written in assembly | `code_dup`, the label the macro writes | `.text`, so the machine code follows the call |
| `defword "NAME", name` | A word written in Forth | `docol` | `.data`, so the execution tokens follow the call |

Nothing calls `defword`. Since ticket 006 every word written in Forth is built by `:` while
mforth runs, so the macro stands as the assemble-time statement of what such a word is, beside
the `defcode` that defines the other kind.

A call carries all three cases at once: `defcode "DUP", dup`. The macro is lowercase because
it is assemble-time machinery, like `db` or `align`; `"DUP"` is uppercase because it is the
name a programmer types at DUP; `dup` is lowercase because it is the stem of the labels the
macro writes, `header_dup`, `xt_dup` and `code_dup`. The rule is in
`docs/system/inner-interpreter.md`.

Each macro redefines `PREVIOUS_HEADER`, a nasm `%define`, to the header it just laid down. The
next header links back to it. This is why the order words appear in the source is the order
they are chained in.

`latest` holds the address of the newest header, and every walk starts there. The cell is
declared in `src/compiler.asm` beside `here` and `state`, because `create_header` writes it
each time a word is defined. `main` stores the starting value into it, because `PREVIOUS_HEADER`
has to be read after every header the assembler lays down, and `main` is the only code that
comes after all the `%include` lines.

A header laid down after that line in source order would still be chained, but no walk would
reach it, and nothing reports that: the source assembles, the binary links, and FIND returns 0
for a name that is in the dictionary. Every word lives in an included file, and all of those
come before `main`, so a new word is reachable wherever it is added.

## FIND

`FIND ( c-addr u -- xt )` takes the address of a name and its length, and leaves the execution
token of the word with that name, or 0. It starts at `latest` and follows the links back. For
each word it compares the length first and calls libc `memcmp` only when the lengths match.
The comparison is case-sensitive: `DUP` finds DUP and `dup` finds nothing.

The walk is `find_name` in `src/words.asm`, an assembly subroutine taking the address in rdi
and the length in rsi and leaving the answer in rax. The FIND word is a wrapper that moves the
two arguments off the data stack and the answer back onto it. The outer interpreter calls
`find_name` for every word a person types, so it does not go through the Forth machine to
reach the dictionary.

`find_name` keeps three values in registers that libc gives back untouched: r14 holds the
header it is looking at, r15 the name it is looking for, and rbp that name's length. All three
are callee-saved, which is why `memcmp` leaves them alone, and nothing else in mforth holds a
value in any of them. The `push rbp` on entry is what puts rsp back on a 16-byte boundary for
the call to `memcmp` — see `docs/system/inner-interpreter.md`.

The Forth 2012 standard defines `FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )`: it takes a
counted string and leaves a flag saying whether the word is immediate. mforth takes an address
and a length, and leaves no flag, because the flags of a word are readable at `[xt - 8]`.

`EXECUTE ( xt -- )` takes an execution token off the data stack and jumps through its code
field. It is NEXT's last instruction with the token taken from the stack instead of the thread.

## Headers built while mforth runs

`create_header` in `src/compiler.asm` writes this same layout for a word a person defines, and
writes the new header's address into `latest`. The two macros and that subroutine are the only
code that writes a header. `docs/system/compiler.md` covers it.

The chain therefore crosses two sections. A compiled header sits in the `.bss` region
`dictionary_space` and links back to INTERPRET, the last header the assembler laid down in
`.data`. `find_name` walks across the join without knowing it is there.

`find_name` reaches a header's flags cell by calling `header_flags` in `src/compiler.asm`
rather than doing the name-rounding arithmetic itself. `create_header`, `:` and `;` call the
same subroutine, so the rounding is written once in code and once in the macro.
