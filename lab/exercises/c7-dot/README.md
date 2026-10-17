# C7 · four floats at once

Return the dot product of two arrays of floats, four elements at a time.

```c
float dot(const float *a, const float *b, long n);
```

| What | Where it is |
|------|-------------|
| `a`, the address of the first float | `rdi` |
| `b`, the same for the other array | `rsi` |
| `n`, how many floats each array has | `rdx` |
| The float you return | the low 32 bits of `xmm0` |

The dot product is `a[0]*b[0] + a[1]*b[1] + ... + a[n-1]*b[n-1]`.

These are floats, four bytes each, not doubles. An `xmm` register holds four
of them side by side, and the `ps` instructions (*packed single*) work on all
four lanes at once. Use them: one `mulps` instead of four `mulss`.

Three promises from the test make that easier:

- `n` is always a multiple of 4, so there is never a leftover element. It
  may be 0.
- Both arrays start on a 16-byte boundary. See hint 1 for why that matters.
- Every sum is exact, so the order you add things in doesn't change the
  answer.

The file is `lab/exercises/c7-dot/dot.asm`. The section *Four at once* in the
tier notes covers the instructions.

```sh
./check c7
```

```sh
./debug c7
```

| Type | What it does |
|------|--------------|
| `p $xmm0.v4_float` | Print all four floats in `xmm0` |
| `x/4fw $rdi` | Show four floats in memory at `rdi` (*w*ord: four bytes) |

<details>
<summary>Hint 1: loading four floats</summary>

`movaps xmm1, [rdi + rcx*4]` loads 16 bytes, four floats, starting at
element `rcx`. The *a* is *aligned*: the address must be a multiple of 16, or
the instruction faults. `movups` (*unaligned*) has no such rule.

`mulps` and `addps` can take their second operand from memory, with the same
rule as `movaps`: a multiple of 16. The test's arrays are aligned, and the
address moves 16 bytes at a time, so it stays that way.

</details>

<details>
<summary>Hint 2: the loop</summary>

Keep four running sums in `xmm0`, one per lane, starting at 0.0 (`xorps
xmm0, xmm0`). Each time round, load four of `a`, multiply them by four of `b`
with `mulps`, and add the four products to the four sums with `addps`. Then
move on four elements: `add rcx, 4`.

</details>

<details>
<summary>Hint 3: four sums into one</summary>

After the loop the lanes of `xmm0` hold `s0 s1 s2 s3`. Fold them in half,
then in half again:

| Instruction | What it does |
|-------------|--------------|
| `movhlps xmm1, xmm0` | Copy the high two lanes of `xmm0` into the low two of `xmm1` |
| `addps xmm0, xmm1` | Lanes 0 and 1 are now `s0+s2` and `s1+s3` |
| `movaps xmm1, xmm0` then `shufps xmm1, xmm1, 1` | Put lane 1 in lane 0 of `xmm1` |
| `addss xmm0, xmm1` | Lane 0 is the total |

Only lane 0 is the answer. What's left in the other three doesn't matter.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
dot:
        xorps   xmm0, xmm0              ; four sums of 0.0
        ; if n is 0, return
        xor     ecx, ecx                ; i = 0
.next:
        ; xmm1 = a[i..i+3]
        ; xmm1 = xmm1 * b[i..i+3]
        ; xmm0 = xmm0 + xmm1
        ; i += 4, and loop while i < n
        ; add the four lanes of xmm0 together
        ret
```

</details>

## When it passes

Run `./debug c7` and continue with `c` to the case `dot({1, 2, ..., 8},
{1, 2, ..., 8}, 8)`. Step through the loop with `si`, and after each
`addps` print `p $xmm0.v4_float`. Twice round the loop:

```text
{1, 4, 9, 16}
{26, 40, 58, 80}
```

Then watch the fold: after the second `addps`, lanes 0 and 1 hold 84 and
120, and after `addss` lane 0 holds the total, 204. A loop doing one float at
a time would have gone round eight times.
