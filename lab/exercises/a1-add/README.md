# A1 · add

Return the sum of two numbers.

```c
long add(long a, long b);
```

| What | Where it is |
|------|-------------|
| `a` | `rdi` |
| `b` | `rsi` |
| The sum you return | `rax` |

The file is `lab/exercises/a1-add/add.asm`.

```sh
./check a1
```

```sh
./debug a1
```

<details>
<summary>Hint 1: two operands</summary>

`add rax, rsi` adds `rsi` to `rax` and leaves the sum in `rax`. The left
operand is both an input and the answer.

</details>

<details>
<summary>Hint 2: getting a into rax</summary>

Neither argument arrives in `rax`. Copy one of them there with `mov`, then
add the other one to it.

</details>

## When it passes

Look at the last case, `add(4000000000, 5000000000)`. Change your code to
work on the 32-bit names, `eax`, `edi` and `esi`, and run `./check a1` again.
Then run `./debug a1`, continue to that case with `c`, and step through it
with `si`. Watch the top half of `rax` as you go. Change it back afterwards.
