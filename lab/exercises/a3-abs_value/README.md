# A3 · abs

Return a number without its sign.

```c
long abs_value(long x);
```

| What | Where it is |
|------|-------------|
| `x` | `rdi` |
| `x` if it's zero or more, `-x` if it's negative | `rax` |

C calls this function `abs`. nasm won't take `abs` as a label, because it's
one of nasm's own words, so here it's `abs_value`.

The file is `lab/exercises/a3-abs_value/abs_value.asm`.

```sh
./check a3
```

```sh
./debug a3
```

Two instructions you'll want:

| Instruction | What it does |
|-------------|--------------|
| `neg rax` | `rax = 0 - rax` |
| `jns .done` | Jump if the sign flag is not set: the last result was zero or more. `js` is its twin |

<details>
<summary>Hint 1: is it negative?</summary>

`test rax, rax` sets the flags from `rax` without changing it. The sign flag
is the top bit of a number, which is set exactly when it's negative.

</details>

<details>
<summary>Hint 2: the shape of it</summary>

```x86asm
abs_value:
        mov     rax, rdi
        test    rax, rax
        ; jump to .done if it isn't negative
        ; otherwise negate it
.done:
        ret
```

</details>

## When it passes

The last case is `abs_value(-9223372036854775808)`, and the answer it expects
is `-9223372036854775808`: still negative. Run `./debug a3`, continue to that
case with `c`, and step through it with `si`. Print `rax` in hex with
`p/x $rax` before and after `neg`. Why can't the answer be positive?
