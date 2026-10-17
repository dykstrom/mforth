# A5 · sum an array

Return the sum of `n` numbers.

```c
long sum(const long *a, long n);
```

| What | Where it is |
|------|-------------|
| `a`, the address of the first number | `rdi` |
| `n`, how many there are | `rsi` |
| The sum you return | `rax` |

When `n` is 0, return 0.

The file is `lab/exercises/a5-sum/sum.asm`.

```sh
./check a5
```

```sh
./debug a5
```

<details>
<summary>Hint 1: reaching a[i]</summary>

Each `long` is eight bytes, so `a[i]` is at `rdi + i*8`. x86-64 can say that
in one operand: `[rdi + rcx*8]`, with `i` kept in `rcx`. The multiplier can
be 1, 2, 4 or 8: one for each size of integer a register can hold.

`add` can take that operand directly, so the loop never needs a register to
hold the element in.

</details>

<details>
<summary>Hint 2: when n is 0</summary>

Check `rsi` before the loop. Run the loop once on an empty array and it adds
a number that isn't there. One of the test cases puts a 99 just past the end
of an empty array to catch that.

</details>

<details>
<summary>Hint 3: the shape of it</summary>

```x86asm
sum:
        xor     eax, eax                ; total = 0
        ; if n is 0, return
        xor     ecx, ecx                ; i = 0
.next:
        ; total += a[i]
        ; i++, and loop while i < n
.done:
        ret
```

</details>

## When it passes

Run `./debug a5` and type `x/3dg $rdi`: three numbers in memory at `rdi`,
`d` for decimal, `g` for *giant*, eight bytes each. That's the whole of the
first case's array. Then step through the loop with `si`, and watch `rcx`
and `rax` change together.
