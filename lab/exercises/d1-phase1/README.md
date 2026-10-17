# D1 · phase 1

Find the string `phase1` accepts.

```c
int phase1(const char *input);
```

There is no source for `phase1`, only the machine code. Read the tier notes
first if you haven't: they cover the gdb commands for reading it.

Your answer goes between the quotes in
`lab/exercises/d1-phase1/phase1.asm`:

```x86asm
input:  db      "", 0
```

```sh
./check d1
```

```sh
./debug d1
```

<details>
<summary>Hint 1: where to look</summary>

`x/20i $pc` shows the whole phase: it's eight instructions. One of them
calls a libc function you know.

</details>

<details>
<summary>Hint 2: what strcmp is given</summary>

`strcmp` compares the two strings at `rdi` and `rsi`, and returns 0 when
they're equal. Your input is already in `rdi` when the phase starts. What
goes into `rsi`?

</details>

<details>
<summary>Hint 3: reading the address</summary>

`movabs rsi,0x4020…` puts a number in `rsi`, and the number is the address
of a string. `x/s` followed by that number shows it. Or `ni` until the
arrow is on the `call`, then `x/s $rsi`.

</details>

## When it passes

Run `./debug d1` again and `ni` past the `call` with your right answer, then
`p $eax`. Then put a wrong answer back and do the same. `strcmp` returns
more than "equal or not": what do the numbers mean? `test`, `sete` and
`movzx` then turn any of them into the 0 or 1 the phase returns.
