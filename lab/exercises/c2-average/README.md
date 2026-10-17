# C2 · average

Return the mean of `n` doubles.

```c
double average(const double *a, long n);
```

| What | Where it is |
|------|-------------|
| `a`, the address of the first double | `rdi` |
| `n`, how many there are | `rsi` |
| The mean you return | `xmm0` |

When `n` is 0, return 0.0.

Integer and floating-point arguments are counted separately. `a` and `n`
take the first two integer registers, and the result still goes in `xmm0`,
the first floating-point one.

The file is `lab/exercises/c2-average/average.asm`.

```sh
./check c2
```

```sh
./debug c2
```

gdb stops each time the test calls `average`. In this tier the register
window shows the `xmm` registers. Two commands are worth knowing here:

| Type | What it does |
|------|--------------|
| `x/3fg $rdi` | Show three doubles in memory, starting at `rdi` (*f*loat, *g*iant: eight bytes) |
| `p $xmm0.v2_double[0]` | Print the double in the low half of `xmm0` |

<details>
<summary>Hint 1: reaching a[i]</summary>

Each double is eight bytes, so `a[i]` is at `rdi + i*8`. x86-64 can say that
in one operand: `[rdi + rcx*8]`, with `i` kept in `rcx`.

`addsd` can take that operand directly, so the loop never needs a register to
hold the element in.

</details>

<details>
<summary>Hint 2: dividing by n</summary>

`divsd` divides one double by another, and `n` is an integer. `cvtsi2sd xmm1,
rsi` converts it: *convert signed integer to scalar double*.

</details>

<details>
<summary>Hint 3: when n is 0</summary>

Check `rsi` before the loop. Run the loop once on an empty array and it
reads a number that isn't there. Divide by 0.0 and the answer is NaN. One of
the test cases puts a 99 just past the end of an empty array to catch the
first mistake.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
average:
        pxor    xmm0, xmm0              ; sum = 0.0
        ; if n is 0, return
        xor     ecx, ecx                ; i = 0
.next:
        ; sum += a[i]
        ; i++, and loop while i < n
        ; turn n into a double, divide
        ret
```

</details>

## When it passes

Look at the case `average({0.1, 0.2}, 2)` in the output. The expected value
is 0.15000000000000002, not 0.15. Run `./debug c2`, continue to that case
with `c`, and watch `xmm0` as the two numbers are added. Where does the extra
2 come from?
