# C · Floating point

Read this before the exercises. It covers what this tier uses that the talk
didn't.

## The xmm registers

Floating point has its own sixteen registers, `xmm0` to `xmm15`. Each is 128
bits wide, which is room for two doubles or four floats side by side. Most of
this tier uses just the low 64 bits: one double per register, the *scalar*
case.

The instruction names say which case they mean in their last two letters:

| Suffix | Means | Example |
|--------|-------|---------|
| `sd` | **s**calar **d**ouble: one 64-bit double | `addsd xmm0, xmm1` |
| `ss` | **s**calar **s**ingle: one 32-bit float | `addss xmm0, xmm1` |
| `pd` | **p**acked **d**ouble: two doubles at once | `addpd xmm0, xmm1` |
| `ps` | **p**acked **s**ingle: four floats at once | `addps xmm0, xmm1` |

## The instructions you'll need

| Instruction | What it does |
|-------------|--------------|
| `movsd xmm0, [rdi]` | Load a double from memory. Also `movsd [rdi], xmm0` to store one, and `movsd xmm1, xmm0` to copy one |
| `addsd`, `subsd`, `mulsd`, `divsd` | Arithmetic, the result left in the first operand. The second may be a register or memory |
| `sqrtsd xmm0, xmm1` | Square root |
| `cvtsi2sd xmm0, rax` | Integer to double |
| `cvttsd2si rax, xmm0` | Double to integer, rounding toward zero (the extra `t` is *truncate*) |
| `ucomisd xmm0, xmm1` | Compare, setting the flags for a jump |
| `pxor xmm0, xmm0` | Zero a register: 0.0 |

## Doubles in and out of a function

The System V convention gives floating-point arguments registers of their
own, `xmm0` to `xmm7`, counted separately from the integer ones:

```c
double scale(const double *a, long n, double factor);
//                     rdi       rsi         xmm0     -> returns in xmm0
```

A double comes back in `xmm0`. No `xmm` register is callee-saved: a function
may change any of them, and has to assume anything it calls does too.

## Constants

No instruction takes a floating-point number as an immediate, so `mov xmm0,
1.5` doesn't exist. The constant has to live in memory and be loaded from
there:

```x86asm
        DEFAULT ABS

        section .rodata
half:   dq      0.5             ; nasm writes the bits of the double 0.5

        section .text
        ; ...
        mulsd   xmm0, [half]
```

`DEFAULT ABS` tells nasm that `[half]` means the absolute address of `half`.
That's what the programs here want, because they're linked with `-no-pie`.
nasm 3 warns if a file names an address in memory without saying.

## Comparing

`ucomisd` sets the flags the way an *unsigned* integer comparison does, so
the jumps that follow it are the unsigned ones:

| After `ucomisd xmm0, xmm1` | Jumps if |
|----------------------------|----------|
| `ja` | xmm0 > xmm1 |
| `jae` | xmm0 >= xmm1 |
| `jb` | xmm0 < xmm1 |
| `jbe` | xmm0 <= xmm1 |
| `je` | xmm0 == xmm1 |
| `jp` | either one is NaN: the two are *unordered* |

`jg` and `jl` assemble and run, but they test the wrong flags, and they get
it wrong without any warning.

## In gdb

| Type | What it shows |
|------|---------------|
| `p $xmm0.v2_double` | Both halves of `xmm0` as doubles |
| `p $xmm0.v4_float` | All four quarters as floats |
| `x/4fg $rdi` | Four doubles in memory at `rdi` |
| `tui reg sse` | Switch the register window to the `xmm` registers (`./debug` already does this in this tier) |
| `tui reg general` | And back to the integer ones |
