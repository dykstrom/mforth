# C4 · clamp

Keep `x` between `lo` and `hi`.

```c
double clamp(double x, double lo, double hi);
```

| What | Where it is |
|------|-------------|
| `x` | `xmm0` |
| `lo`, the smallest answer allowed | `xmm1` |
| `hi`, the largest | `xmm2` |
| The answer you return | `xmm0` |

Return `lo` if `x` is below `lo`, `hi` if `x` is above `hi`, and `x`
otherwise. If `x` is NaN, return it unchanged: a NaN in should be a NaN out,
so whoever called you can see something went wrong.

The file is `lab/exercises/c4-clamp/clamp.asm`. The section *Comparing* in the
tier notes is the one this exercise is about.

```sh
./check c4
```

```sh
./debug c4
```

To see the flags after a compare, type `p $eflags`. gdb lists the ones that
are set: `CF`, `PF` and `ZF` are the three `ucomisd` uses.

<details>
<summary>Hint 1: which jumps</summary>

`ucomisd xmm0, xmm1` compares like an unsigned integer compare, so the jumps
after it are `jb` (below) and `ja` (above). `jl` and `jg` assemble, run, and
look at flags that `ucomisd` always clears. The test has cases that catch
each of them.

</details>

<details>
<summary>Hint 2: returning lo or hi</summary>

The answer has to end up in `xmm0`. `movsd xmm0, xmm1` copies `lo` there.

</details>

<details>
<summary>Hint 3: the NaN</summary>

When either side is NaN, `ucomisd` sets `PF`, and also `CF` and `ZF`. `CF`
set is what `jb` jumps on, so a NaN looks below everything. Check `jp` first,
straight after the compare: the flags are still there for a second jump.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
clamp:
        ucomisd xmm0, xmm1
        ; NaN? return x
        ; below lo? go to .low
        ucomisd xmm0, xmm2
        ; above hi? go to .high
        ret
.low:
        ; xmm0 = lo
        ret
.high:
        ; xmm0 = hi
        ret
```

</details>

## When it passes

Run `./debug c4` and continue with `c` to the case `clamp(NaN, 0, 1)`. Step
over the first `ucomisd` with `si` and look at `p $eflags`. Then compare it
with the flags after the same instruction in `clamp(-3, 0, 10)`. Which flags
are set for the NaN that aren't for the -3?

There is a shorter way to write `clamp`: `maxsd` and `minsd` pick the larger
and the smaller of two doubles, with no jumps at all. When one side is NaN
they return their second operand, whichever that is. Can you order the
operands so that a NaN still comes out?
