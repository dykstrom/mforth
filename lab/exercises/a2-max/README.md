# A2 · max

Return the larger of two numbers.

```c
long max(long a, long b);
```

| What | Where it is |
|------|-------------|
| `a` | `rdi` |
| `b` | `rsi` |
| The larger one, which you return | `rax` |

Both numbers are signed, so -1 is less than 0.

The file is `lab/exercises/a2-max/max.asm`.

```sh
./check a2
```

```sh
./debug a2
```

## Signed and unsigned jumps

`cmp rdi, rsi` works out `rdi - rsi` and keeps only the flags. The jump
after it decides how to read them, and there are two sets of jumps:

| Signed | Unsigned | Jumps if the left one is |
|--------|----------|--------------------------|
| `jl` | `jb` | less (*below*) |
| `jle` | `jbe` | less or equal |
| `jg` | `ja` | greater (*above*) |
| `jge` | `jae` | greater or equal |

The bits of -1 are all ones. Read as unsigned, that's the largest number a
register can hold. Pick from the wrong column and the test's negative cases
fail.

<details>
<summary>Hint 1: a guess</summary>

Put `a` in `rax` first, as the stub already does. Then the only question is
whether to replace it with `b`.

</details>

<details>
<summary>Hint 2: the shape of it</summary>

```x86asm
max:
        mov     rax, rdi                ; guess a
        cmp     rdi, rsi
        ; jump to .done if a is greater or equal
        ; otherwise b is the answer
.done:
        ret
```

A label that starts with a dot belongs to the label above it, so every
function can have its own `.done`.

</details>

<details>
<summary>Hint 3: no jump at all (optional)</summary>

`cmovl rax, rsi` copies `rsi` to `rax` only if the last comparison said
*less*. Every jump has a `cmov` to match: `cmovge`, `cmovb`, and so on.

</details>

## When it passes

Change your jump to its unsigned twin, `jge` to `jae` or `jl` to `jb`, and
run `./check a2`. Then run `./debug a2`, continue to the case `max(-1, 0)`
with `c`, and step past the `cmp` with `si`. Type `p $eflags`: gdb names the
flags that are set. The unsigned jumps read `CF`, the carry flag, which says
the subtraction had to borrow. The signed ones read `SF` and `OF`, the sign
of the result and whether it overflowed. Which of them did `-1 - 0` set?
Change the jump back afterwards.
