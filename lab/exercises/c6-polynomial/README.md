# C6 · polynomial

Work out a polynomial at `x`.

```c
double polynomial(const double *c, long n, double x);
```

| What | Where it is |
|------|-------------|
| `c`, the address of the first coefficient | `rdi` |
| `n`, how many there are | `rsi` |
| `x` | `xmm0` |
| The value you return | `xmm0` |

The answer is `c[0] + c[1]*x + c[2]*x*x + ... + c[n-1]*x^(n-1)`. When `n` is
0, return 0.0.

Raising `x` to every power is slow and takes a register per power. Horner's
rule needs neither. It writes `1 + 2x + 3x²` inside out:

```text
((3) * x + 2) * x + 1
```

Start from the last coefficient. Then, for each one below it, multiply what
you have by `x` and add that coefficient. One running value, one multiply and
one add per coefficient.

The file is `lab/exercises/c6-polynomial/polynomial.asm`.

```sh
./check c6
```

```sh
./debug c6
```

<details>
<summary>Hint 1: x is in the way</summary>

`x` arrives in `xmm0`, and the answer has to leave there. Copy `x` to another
register first, `movsd xmm1, xmm0`, and build the answer up in `xmm0`.

</details>

<details>
<summary>Hint 2: an easy start</summary>

Start the running value at 0.0, not at `c[n-1]`. The first time round, 0.0
times `x` is still 0.0, and adding `c[n-1]` gives the start you wanted. The
loop then needs no special first step.

</details>

<details>
<summary>Hint 3: walking backwards</summary>

Count `rsi` down from `n` to 1. The coefficient to add is then `c[rsi - 1]`,
which x86-64 can say in one operand: `[rdi + rsi*8 - 8]`.

`dec rsi` sets the zero flag when `rsi` reaches 0, so `jnz` straight after it
loops without a `cmp`.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
polynomial:
        movsd   xmm1, xmm0              ; x
        pxor    xmm0, xmm0              ; sum = 0.0
        ; if n is 0, return
.next:
        ; sum = sum * x
        ; sum = sum + c[rsi - 1]
        ; rsi--, and loop while it isn't 0
        ret
```

</details>

## When it passes

Run `./debug c6` and continue with `c` to the case
`polynomial({1, 2, 3}, 3, 2)`. Step through the loop with `si`, and after each
`addsd` print the running value:

```text
p $xmm0.v2_double[0]
```

You should see 3, then 8, then 17: `3`, `3*2 + 2`, `8*2 + 1`. That is
Horner's rule, one coefficient per time round.
