# C3 · hypot

Return the length of the hypotenuse of a right triangle with sides `x` and
`y`: the square root of `x*x + y*y`.

```c
double hypot(double x, double y);
```

| What | Where it is |
|------|-------------|
| `x` | `xmm0` |
| `y` | `xmm1` |
| The length you return | `xmm0` |

Two double arguments take the first two floating-point registers, in order.
Nothing here touches memory or an integer register.

The file is `lab/exercises/c3-hypot/hypot.asm`.

```sh
./check c3
```

```sh
./debug c3
```

<details>
<summary>Hint 1: squaring</summary>

A square is a number multiplied by itself, and an instruction can name the
same register twice: `mulsd xmm0, xmm0`.

</details>

<details>
<summary>Hint 2: the square root</summary>

`sqrtsd xmm0, xmm1` puts the square root of `xmm1` in `xmm0`. Both operands
can be the same register.

</details>

<details>
<summary>Hint 3: may I change xmm1?</summary>

Yes. No `xmm` register is callee-saved, so a function may change any of
them without putting them back.

</details>

## When it passes

Run `./debug c3`, and stop at the case `hypot(1, 1)` with `c`. Step to just
after `sqrtsd` and look at the result in hex as well as in decimal:

```text
p $xmm0.v2_double[0]
p/x $xmm0.v2_int64[0]
```

The square root of 2 has no end, but a double has 52 bits after the point.
`sqrtsd` always rounds to the nearest double, so every x86-64 machine gives
exactly those bits.

The real `hypot` in libm is longer than four instructions. Try your version
in your head with `x` = 1e200: what does `x * x` come to?
