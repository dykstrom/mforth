# C1 · c_to_f

Convert a temperature from Celsius to Fahrenheit.

```c
double c_to_f(double c);
```

| What | Where it is |
|------|-------------|
| `c`, degrees Celsius | `xmm0` |
| The degrees Fahrenheit you return | `xmm0` |

The formula is `c * 9 / 5 + 32`.

A double doesn't arrive in `rdi`. Floating-point arguments have registers of
their own, `xmm0` to `xmm7`, and a double result goes back in `xmm0`. Here
the argument and the result share the register, so the work can happen
where `c` already is.

The file is `lab/exercises/c1-c_to_f/c_to_f.asm`. The tier notes cover
everything this exercise uses: read them first if you haven't.

```sh
./check c1
```

```sh
./debug c1
```

gdb stops each time the test calls `c_to_f`, with the `xmm` registers in the
register window.

| Type | What it does |
|------|--------------|
| `p $xmm0.v2_double[0]` | Print the double in the low half of `xmm0` |
| `x/fg &nine` | Show the double stored at the label `nine` |

<details>
<summary>Hint 1: where 9, 5 and 32 come from</summary>

`mulsd xmm0, 9` doesn't exist: no instruction takes a double as an
immediate. Put each number in `.rodata` with `dq`, and give it a label:

```x86asm
        section .rodata
nine:   dq      9.0
```

The `.0` matters. `dq 9` writes the integer 9, whose bits are a tiny double
close to zero.

</details>

<details>
<summary>Hint 2: using them</summary>

`mulsd`, `divsd` and `addsd` can all take their second operand from memory:
`mulsd xmm0, [nine]`. Each leaves its result in `xmm0`, where the next one
picks it up.

</details>

<details>
<summary>Hint 3: the shape of it</summary>

```x86asm
c_to_f:
        ; xmm0 = xmm0 * 9
        ; xmm0 = xmm0 / 5
        ; xmm0 = xmm0 + 32
        ret
```

</details>

## When it passes

Look at the case `c_to_f(1)`. The answer is 33.8 on paper, but the test
expects 33.799999999999997. Run `./debug c1` and continue with `c` until
`xmm0` holds 1. Step through with `si`, printing `p $xmm0.v2_double[0]`
after each instruction. Which step leaves a number that isn't exact?

Then think about `c * 1.8 + 32`, which is the same formula on paper. The test
leaves out 37 °C, body temperature, on purpose: for 37 the two ways give
answers that differ in the last bit.
