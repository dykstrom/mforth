# D2 · phase 2

Find the input `phase2` accepts.

```c
int phase2(const char *input);
```

No source again. This one calls a libc function that reads the input
apart, then checks the pieces in a loop.

Your answer goes between the quotes in
`lab/exercises/d2-phase2/phase2.asm`.

```sh
./check d2
```

```sh
./debug d2
```

<details>
<summary>Hint 1: what sscanf is given</summary>

`sscanf(input, format, …)` reads the input the way the format says, and
stores what it reads at the addresses that follow. `x/s` on the format
says what kind of input the phase wants, and how many pieces.

The phase is longer than `disas` shows: it stops at the label
`phase2.next`. `x/30i phase2` shows all of it.

</details>

<details>
<summary>Hint 2: where the numbers go</summary>

The four addresses after the format are `rsp`, `rsp+8`, `rsp+16` and
`rsp+24`: room on the stack for four longs, side by side. Call them `n[0]`
to `n[3]`.

Put any four numbers in your input, stop just after the `call` with
`b *address` on the instruction after it, and `x/4gd $rsp` shows them where
`sscanf` left them.

</details>

<details>
<summary>Hint 3: the first number</summary>

Right after the call come two checks: how many numbers `sscanf` read, and a
`cmp` against `QWORD PTR [rsp]`, which is `n[0]`.

</details>

<details>
<summary>Hint 4: the loop</summary>

`rcx` counts from 1 to 3. Each time round, `[rsp+rcx*8-0x8]` is `n[i-1]` and
`[rsp+rcx*8]` is `n[i]`. Between loading the one and comparing with the
other are two instructions. Work out the second number from the first, then
the third from the second.

</details>

## When it passes

Try your answer with extra spaces between the numbers, or a fifth number on
the end. Does the phase still accept it? Which instruction would have to
change for it not to?
