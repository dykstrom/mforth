# Interpreter walkthrough

What happens between a person typing a line and mforth answering it. The other files in this
folder describe one area each; this one follows a single line through all of them.

## Startup

`main` in `src/mforth.asm` runs before any Forth does, in this order:

1. `sub rsp, 8` puts the machine stack back on a 16-byte boundary. No word touches rsp again.
2. `setvbuf` asks libc for line buffering, because standard output is a pipe under
   `docker exec` — see `docs/system/build-and-tests.md`.
3. `puts` prints the banner.
4. DSP and RSP are set to the top of their regions in `src/inner.asm`. Both stacks grow down.
5. `latest` is set to `PREVIOUS_HEADER`, the last header the assembler laid down. This is the
   only place it can be set, because every `%include` has to have been read first.
6. `refill` reads the first line. When there is no input at all, `main` jumps to `code_bye`.
7. IP is pointed at `interpreter`, the one-cell thread in `src/outer.asm`, and `NEXT` runs.

`NEXT` reads the token in that cell, steps IP past it, and jumps through the code field. The
token is INTERPRET's, so the interpreter starts.

## One line

```mermaid
sequenceDiagram
    actor Person
    participant INTERPRET
    participant parse_word
    participant find_name
    participant Word as The word's code
    Person->>INTERPRET: 2 3 + .
    INTERPRET->>INTERPRET: mov IP, interpreter
    INTERPRET->>parse_word: the next word of the line
    parse_word-->>INTERPRET: "2", one character
    INTERPRET->>find_name: is there a word called 2?
    find_name-->>INTERPRET: rax 0
    INTERPRET->>INTERPRET: to_number reads 2; state is 0, so push it
    Note over INTERPRET,find_name: 3 takes the same path
    INTERPRET->>parse_word: the next word
    parse_word-->>INTERPRET: "+", one character
    INTERPRET->>find_name: is there a word called +?
    find_name-->>INTERPRET: rax xt_plus
    INTERPRET->>Word: mov W, rax then jmp [W]
    Word-->>INTERPRET: 5 replaces the two; its own NEXT reads the loop cell
    Note over INTERPRET,Word: . runs the same way and prints "5 "
    INTERPRET->>parse_word: the next word
    parse_word-->>INTERPRET: rdx 0, the line is spent
    INTERPRET->>Person: " ok"
```

INTERPRET's first instruction is `mov IP, interpreter`. That is what makes the loop: `NEXT`
had just stepped IP past the single cell, and putting IP back on it means the next `NEXT` to
run anywhere reads INTERPRET's token again. A word reached from the interpreter ends with its
own `NEXT` and so comes back here without knowing where it was called from.

## What INTERPRET does with one word

`find_name` is asked before `to_number`. That order is what makes `-` the name of the
subtraction word rather than text that failed to convert.

| What `parse_word` handed back | `state` is 0 | `state` is -1 |
|---|---|---|
| A word that is not immediate | `mov W, rax`, `jmp [W]` | `comma_cell` appends its token |
| A word whose flags at `[xt - 8]` carry `F_IMMEDIATE` | `mov W, rax`, `jmp [W]` | The same: run it |
| Text `to_number` reads as a number | Push it on the data stack | `comma_cell` appends `xt_lit`, then the value |
| Neither | Print `<name> ?`, store 0 in `state`, read the next line | The same |
| Nothing: the line is spent | Print ` ok`, read the next line | The same |

`state` lives in `src/compiler.asm` and is the whole of the difference between running a line
and compiling one. `:` stores -1 in it and `;` stores 0, so a definition may span as many
lines as it likes: `state` is a cell, not something a line owns.

## Where the line ends

`refill` reads characters with `getchar` until a line feed or end of input, and stores them in
`input_buffer` without the line feed. `parse_word` walks `input_offset` along that buffer,
over spaces and tabs and then over one word, and hands back where the word starts and how long
it is. Nothing copies the characters, so what `WORD` leaves is good only until the next line.

End of input after some characters ends that line. End of input before any makes `refill`
answer 0, and INTERPRET jumps to `code_bye`, which calls libc `exit`. That is how Ctrl-D ends
a session, and it is the one path out of mforth.

## Where to read next

| Area | File |
|---|---|
| `NEXT`, `docol`, EXIT, the two stacks | `docs/system/inner-interpreter.md` |
| Headers, the chain, `find_name` | `docs/system/dictionary.md` |
| The words `find_name` finds | `docs/system/core-words.md` |
| `refill`, `parse_word`, `to_number`, INTERPRET | `docs/system/outer-interpreter.md` |
| `here`, `state`, `create_header`, `:` and `;` | `docs/system/compiler.md` |
| `BRANCH`, `0BRANCH` and the words that compile them | `docs/system/control-flow.md` |
| `EMIT`, `."`, `.S`, `WORDS` | `docs/system/strings.md` |
| The sixteen words written in Forth | `docs/system/prelude.md` |
| `make`, `make run`, `make test` | `docs/system/build-and-tests.md` |
