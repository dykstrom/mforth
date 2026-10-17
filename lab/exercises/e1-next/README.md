# E1 · NEXT

Write NEXT, the inner interpreter: the three instructions that start the
next word in a thread.

```x86asm
next:
        ; load the execution token IP points at into W, step IP past it,
        ; and jump through the code field W points at
```

| What | Where it is |
|------|-------------|
| IP, the address of the next cell of the thread | `rbx` |
| W, the execution token you load | `rax` |

Read the tier notes first: they explain threads, execution tokens and code
fields.

The file is `lab/exercises/e1-next/next.asm`. It holds the whole Forth so
far: `forth`, the way in from C; LIT and BYE; and `next`, which is yours.
Until it's written, `next` jumps straight to BYE, so every thread stops
before its first word, and the test finds an empty stack.

```sh
./check e1
```

```sh
./debug e1
```

gdb stops at `next` each time one word ends and the next one starts. `c`
goes on to the next word. Watch `rbx` step along the thread, eight bytes at a
time.

<details>
<summary>Hint 1: the three steps</summary>

1. Load the cell `IP` points at into `W`. That's the execution token.
2. Add 8 to `IP`, so that it points at the cell after.
3. Jump to the address held in the code field, which is the cell `W` points
   at.

</details>

<details>
<summary>Hint 2: jumping through the code field</summary>

`jmp` can read its target from memory: `jmp [W]` jumps to the address
stored at `W`. Without the brackets it would jump to `W` itself, which is the
code field. That's data, so it would crash.

</details>

<details>
<summary>Hint 3: why step IP before the jump</summary>

The jump never comes back: the word ends by jumping to `next` again. So IP has
to be stepped before the jump or not at all. Stepping it first is also how
LIT finds its number: when LIT starts, IP already points at the cell after
LIT's own token.

</details>

## When it passes

Run `./debug e1` and press `c` once, which takes you to the case
`LIT 2 BYE`. Then:

```text
x/3a $rbx
```

That's the whole thread: `<xt_lit>`, `0x2` and `<xt_bye>`. Now `si` once, to
load the token, and look at what `rax` points at:

```text
x/a $rax
```

gdb shows the code field, `<xt_lit>`, and what it holds, `<lit>`. That's the
address `jmp [W]` is about to jump to. `si` twice more, and you're there.
