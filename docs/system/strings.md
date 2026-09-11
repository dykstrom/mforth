# Strings and introspection

`src/strings.asm`: six words that exist for the person watching. `EMIT` and `TYPE` put
characters on the terminal, `."` and `(.")` print text that a definition carries with it, and
`.S` and `WORDS` say what mforth is holding. Before this file mforth could print numbers and
nothing else.

A string in Forth is an address and a length, not characters with a zero after them. That is
what `WORD` leaves, what a name in a header is, and what `."` lays down. `print_text` is the
one place any of them reaches the terminal.

## The words

| Word | Stack effect | What it does |
|------|--------------|--------------|
| `EMIT` | `( c -- )` | Prints one character, through `putchar`. |
| `TYPE` | `( c-addr u -- )` | Prints u characters starting at c-addr. |
| `."` | `( -- )` | Immediate. Compiles the text up to the closing quote. |
| `(.")` | `( -- )` | Prints the text that follows it in the thread. |
| `.S` | `( -- )` | Prints the depth and then every item, bottom to top. |
| `WORDS` | `( -- )` | Prints every name in the dictionary, newest first. |

`SPACE` is not here. It is `32 EMIT` in `lib/prelude.f`, because Forth can say it — see
`docs/architecture/prelude.md`.

## print_text

`print_text` takes an address in rdi and a length in rsi and calls `printf` with the format
`"%.*s"`. The `*` takes the count from the argument in front of the string, so `printf` prints
exactly that many characters and stops. Without it `printf` would read on until it found a
zero byte, and neither a name in the dictionary nor the text inside a definition has one.

It is an assembly subroutine, the way `find_name` is, not a Forth word. It ends in
`jmp printf` rather than a call: the return address its own caller pushed is still on top of
the machine stack, so `printf` returns straight past it, and the stack is aligned the way the
System V ABI wants it at a call. `TYPE`, `(.")` and `WORDS` all print through it.

## What `."` compiles

The text a word prints has to live somewhere, and in threaded code there is nowhere to put it
but the thread. `LIT` already gives that answer for a number. `."` gives the same answer for a
string: it appends the token of `(.")` and then the text straight after it, as a length byte
and the characters, padded out to a cell. The body of `: GREET ." hi" CR ;` is four cells:

```
                +--------------------+
                | xt_paren_dot_quote |
                | 2 h i 0 0 0 0 0    |   the text, padded to one cell
                | xt_cr              |
                | xt_exit            |
                +--------------------+
```

`(.")` reads the length byte at IP, prints that many characters, and steps IP over the length
byte and the text, rounded up to the cell the next token starts on. The arithmetic is
`(length + 8) & -8`: the 8 covers the length byte and rounds up at once. Why the text sits
in the thread rather than in the dictionary with `LIT` and `TYPE` around it is
`docs/adr/0010-compiled-text-lives-in-the-thread.md`.

The one space after `."` is the delimiter and is not printed, so a second space would be. The
text ends at the closing quote, or at the end of the line when there is none — mforth keeps one
line at a time, which is the same answer `(` gives about an unclosed comment.

`."` is immediate, like every word that compiles something. `(.")` is not hidden: mforth gives
it a name for the same reason `LIT` has one, and it appears in `WORDS`.

## .S and WORDS

`.S` prints `<3> 1 2 3 ` for a stack of three. The depth comes first so that an empty stack
prints `<0> ` rather than nothing at all, and each item is followed by a space, which is the
format `.` uses. It reads the stack region between `data_stack_top` and DSP directly. That is
why it is assembly: the stack is where a word's arguments are, not somewhere a word can walk.
The subtraction is `DEPTH`'s, in `src/words.asm`.

`WORDS` is `find_name`'s walk with the comparing taken out. It starts at `latest` and follows
each header's link back, so the newest name comes first: the words a person has defined, then
the sixteen in `lib/prelude.f`, then the assembly words in the order the `%include` lines in
`src/mforth.asm` laid them down. `src/strings.asm` is included last, so its words print first
of the assembly ones.

Both keep their place in r14 across the `printf` calls. `printf` may use any caller-saved
register, and `find_name` explains why r14 and r15 are the free ones.

## What is not checked

- `." text"` typed outside a definition lays the cells down where nothing will run them and
  prints nothing. Nothing reports it, which is the answer the two stacks and the dictionary
  region already give.
- `WORDS` prints a hidden name too. The only hidden word is one that a definition which failed
  left behind, and this is the word that shows it is there.
- `EMIT` passes the cell to `putchar`, which takes an int, so a character larger than a byte
  loses its top.
- There is no string library: no comparison, no counted-string arithmetic, no string variables.

## Names with a quote in them

`."` and `(.")` are written in single quotes in the source — `defcode '."', dot_quote` — because
nasm does not read a backslash inside a double-quoted string, so there is no way to put a quote
in one. The name is otherwise a name like any other, which is the point Forth keeps making:
`."` is a word the interpreter looks up, not punctuation the parser knows about.

## Testing

`tests/strings.f` prints a character, prints a string through `WORD` and `TYPE`, defines
`GREET` with `."` and runs it, shows a stack of three with `.S` and then adds it up to prove
`.S` left it alone, shows an empty stack, uses `SPACE`, pins the silence of `."` outside a
definition, and ends with `WORDS`.

`tests/strings.expected` holds the whole name list, so a word added to assembly or to the
prelude changes this file as well as the banner line.
