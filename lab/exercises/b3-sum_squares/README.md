# B3 · sum_squares

Add up the squares from 1 to `n`, calling a function for each one.

```c
long sum_squares(long n);
long square(long x);
```

`sum_squares(3)` is `1*1 + 2*2 + 3*3`, which is 14. Each square comes from
a call to `square`, which the test provides, not from `imul`: the call is
the point. When `n` is 0, return 0.

| What | Where it is |
|------|-------------|
| `n` | `rdi` |
| The sum you return | `rax` |
| `x`, for `square` | `rdi` |
| What `square` returns | `rax` |

`square` keeps the rules and no more. Every caller-saved register is fair
game for it, and it fills each of them with `0xbad` before it returns. A
count kept in `rcx` comes back as `0xbad`. The test checks your side of the
rules too: `rbx`, `rbp` and `r12` to `r15` must hold, when `sum_squares`
returns, what they held when it was called.

The file is `lab/exercises/b3-sum_squares/sum_squares.asm`.

```sh
./check b3
```

```sh
./debug b3
```

`ni` runs `call square` as a whole. Use it, and look at the registers
afterwards: everything `square` was allowed to change says `0xbad`.

<details>
<summary>Hint 1: what has to survive the call</summary>

The count and the running sum are both needed after every call, so neither
can live in a caller-saved register. Put them in callee-saved ones: `rbx`
and `r12`, say.

Count down from `n` to 1 instead of up. Then `n` itself is the count, and
two registers are enough.

</details>

<details>
<summary>Hint 2: borrowing rbx and r12</summary>

Whoever called `sum_squares` is relying on `rbx` and `r12` as well. `push`
both at the start, and `pop` them at the end in the opposite order.

</details>

<details>
<summary>Hint 3: the rsp case fails</summary>

Count the bytes. `rsp` was 8 off a multiple of 16 on the way in, and two
pushes make it 24 off. One more `sub rsp, 8` makes 32. Undo it before the
pops.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
sum_squares:
        push    rbx
        push    r12
        sub     rsp, 8                  ; 8 + 16 + 8 = 32
        ; rbx = n, r12 = 0
        ; if n is 0, skip the loop
.next:
        mov     rdi, rbx
        call    square
        ; add the square to r12
        ; count rbx down, and loop until it is 0
.done:
        ; the sum in rax
        add     rsp, 8
        pop     r12
        pop     rbx
        ret
```

</details>

## When it passes

Change the `push rbx` at the top into a `push rbp`, and leave the rest as it
is. Which case fails now, and why does `sum_squares` still return the right
sums?
