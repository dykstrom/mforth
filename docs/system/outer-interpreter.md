# Outer interpreter

The outer interpreter reads what a person types and runs it. It lives in `src/outer.asm`. The
inner interpreter walks a thread of execution tokens; the outer one makes those tokens out of
text.

## The loop is one cell of thread

`src/outer.asm` holds a thread of a single cell:

```
interpreter:
        dq      xt_interpret
```

`main` reads the first line, points IP at that cell and runs `NEXT`. INTERPRET's first
instruction is `mov IP, interpreter`, which puts IP back on the cell that `NEXT` just stepped
past. Every path out of INTERPRET therefore returns to INTERPRET:

- A word was found: `mov W, rax` and `jmp [W]`, the same jump `NEXT` makes. That word ends
  with its own `NEXT`, which reads the loop cell.
- The text was a number: push it and run `NEXT`.
- The line is spent, or the word is unknown: read the next line and run `NEXT`.

A word written in Forth returns the same way, because `docol` saves IP and EXIT puts it back.
Nothing in a word knows it was reached from the interpreter rather than from a thread.

A standard Forth calls this loop QUIT and writes it in Forth as `INTERPRET` followed by a
branch back. mforth cannot until BRANCH arrives with ticket 007.

## Reading and splitting

Four assembly subroutines do the work. Each is called the way libc's functions are, with
arguments in registers, so INTERPRET reaches them directly instead of through the Forth
machine.

| Subroutine | Takes | Leaves |
|------------|-------|--------|
| `refill` | nothing | 1 in rax when a line was read, 0 at end of input |
| `parse_word` | nothing | rax the address of the word, rdx its length; rdx is 0 when the line is spent |
| `to_number` | rdi address, rsi length | rax the value, rdx 1 or 0 |
| `find_name` | rdi address, rsi length | rax the execution token or 0 |

`find_name` is in `src/words.asm` — see `docs/system/dictionary.md`. The other three are in
`src/outer.asm`.

`refill` calls libc `getchar` until a line feed or end of input, and stores the characters,
without the line feed, in `input_buffer`. The buffer is 256 bytes in `.bss` beside
`input_length` and `input_offset`. Characters past the end of the buffer are read and dropped,
and nothing reports it. End of input after some characters ends the line; end of input before
any makes `refill` report 0, and INTERPRET then jumps to `code_bye`.

`parse_word` walks from `input_offset` over spaces and tabs, then over the characters of one
word, and moves `input_offset` past it. Nothing else separates words, because the line feed
never reached the buffer. What it leaves points into `input_buffer`, so it is good only until
the next line is read.

## What INTERPRET does with a word

INTERPRET asks `find_name` first and `to_number` second. That order is what makes `-` the name
of the subtraction word rather than text that failed to convert to a number.

`to_number` reads signed decimal only. mforth has no BASE. A minus sign may come first, but a
minus sign alone is not a number.

An unknown word prints `<name> ?` through libc `printf` with the format `"%.*s ?\n"`, then
reads the next line, which drops the rest of the line it was typed on. A line that is
interpreted to the end prints ` ok` through libc `puts` instead. Only that path prints ` ok`,
so a line with an unknown word is not answered with one, and no flag is needed to tell the two
apart.

The data stack is left alone when a word is unknown. A standard Forth empties it.

## The words

| Word | Stack effect | Notes |
|------|--------------|-------|
| `KEY` | `( -- c )` | The next character of the line, or the line feed once the line is spent. It never reads a new line. |
| `WORD` | `( -- c-addr u )` | Wraps `parse_word`. u is 0 when the line is spent. |
| `NUMBER` | `( c-addr u -- n f )` | Wraps `to_number`. The standard spells this `>NUMBER` and converts as far as it can; mforth answers about the whole text. |
| `INTERPRET` | `( -- )` | Handles one word, then loops. |
| `+` | `( n1 n2 -- n3 )` | Added here because ticket 004's example needs it and no other ticket defines it. |
| `-` | `( n1 n2 -- n3 )` | The same. |

INTERPRET does not use KEY. KEY reads from the same buffer, and it does not call `refill`,
because a KEY that read a new line would swallow the line the person is about to type.

## Testing

`tests/interpreter.f` is fed to mforth on standard input by `tests/run.sh`, and the output is
diffed against `tests/interpreter.expected`. It covers `+`, `-`, a stack word, an unknown word
followed by a word that must not run, and PRINT42, which is a word written in Forth reached by
name.

Trailing spaces in the expected file are significant. `.` prints a space after the number and
` ok` begins with one, so a line reading `3  ok` holds two spaces.

## What is not here yet

Nothing compiles. STATE, `:` and `;` arrive with ticket 006, and INTERPRET gains the branch
that appends a token to a definition instead of running it. There is no BASE, no way to load a
file other than piping it on standard input, and no check on either stack.
