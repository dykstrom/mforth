# The sixteen registers, and the rules for calling libc

What each general-purpose register is actually for on a modern 64-bit machine, and what
the System V ABI demands when you `call` into the C library. mforth calls libc and
nothing else — no `syscall` anywhere — so this ABI is the only contract its words have to
honour.

## What the registers are for

There are sixteen general-purpose registers. Only one of them has a job the hardware
insists on; the rest carry either a legacy habit or a convention.

| Register | What uses it, and how strongly |
|---|---|
| `rsp` | **The stack pointer.** `push`, `pop`, `call`, `ret` and the kernel's signal delivery all read and write it. This one is not a convention — you cannot opt out of it. |
| `rbp` | Frame pointer *by convention only*. Nothing in the hardware cares; a debugger walking a backtrace does. |
| `rax` | Accumulator: one operand and part of the result of `mul` and `div`, the function return value, and `al` doubles as the vector-argument count on variadic calls. |
| `rdx` | The other half of `mul`/`div`'s 128-bit result. Also argument 3. |
| `rcx` | Count: shift amounts in `cl`, `rep` string-instruction counts. Also argument 4. |
| `rsi`, `rdi` | Source and destination for the string instructions (`movs`, `lods`, `stos`). Also arguments 2 and 1. |
| `rbx` | Nothing, today. It was the *base* register in 16-bit addressing; in 64-bit code it is a plain register that happens to be preserved across calls. |
| `r8`–`r15` | New with AMD64, so no legacy duties at all. `r8` and `r9` are arguments 5 and 6. |
| `rip` | The instruction pointer. Not addressable as a register; reachable only through RIP-relative addressing — which is exactly what `-no-pie` lets mforth avoid (see `docs/adr/0001-link-non-pie.md`). |
| `rflags` | Condition codes. Also holds the direction flag, which must be clear when you make a call. |

Floating-point and vector values live in `xmm0`–`xmm15`, a separate set. mforth never
touches them, but they matter for one line of `code_dot` — see *Variadic calls* below.

## Passing arguments

| Argument | 1 | 2 | 3 | 4 | 5 | 6 | 7 and beyond |
|---|---|---|---|---|---|---|---|
| Integer / pointer | `rdi` | `rsi` | `rdx` | `rcx` | `r8` | `r9` | on the stack, pushed right to left |
| Floating point | `xmm0` | `xmm1` | `xmm2` | `xmm3` | `xmm4` | `xmm5` | `xmm6`, `xmm7`, then the stack |

The return value comes back in `rax` (a 128-bit one uses `rdx:rax`), or `xmm0` for
floating point.

The `xmm` registers in that row are the bottom of a stack of widths, nested exactly the
way `al` sits inside `rax`. `xmm0`–`xmm15` are 128 bits wide (SSE); AVX widened them to
256 as `ymm0`–`ymm15`; AVX-512 widens them again to 512 as `zmm0`–`zmm31`, and doubles the
count, on the CPUs that have it.

```
┌───────────────────────────────────────────────────────────────────────┐
│                           zmm0   (512 bits)                           │
├───────────────────────────────────┬───────────────────────────────────┤
│                                   │           ymm0   (256)            │
├───────────────────────────────────┼─────────────────┬─────────────────┤
│                                   │                 │   xmm0  (128)   │
└───────────────────────────────────┴─────────────────┴─────────────────┘
```

A `double` argument uses only the low 64 bits of `xmm0`, but the same registers carry
wider values when the type is wider: a 256-bit vector goes in `ymm0`–`ymm7`, a 512-bit one
in `zmm0`–`zmm7` — always the first eight, whatever the width. All of them are
caller-saved. mforth passes no floating-point or vector arguments at all, which is what
makes the `xor eax, eax` below enough.

## Who has to save what

The ABI splits the sixteen registers in two. This is the split that decides how a Forth
lays itself out.

**Caller-saved** — a called function may destroy these. If you want a value to survive,
save it yourself:

```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ rax │ rdi │ rsi │ rdx │ rcx │ r8  │ r9  │ r10 │ r11 │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
  ret  arg1  arg2  arg3  arg4  arg5  arg6
```

**Callee-saved** — a called function must give these back unchanged. Put a value here and
it is still there after `call printf`:

```
┌─────┬─────┬─────┬─────┬─────┬─────┬─────┐
│ rbx │ rbp │ rsp │ r12 │ r13 │ r14 │ r15 │
└─────┴─────┴─────┴─────┴─────┴─────┴─────┘
  IP                DSP   RSP
```

The labels on the second box are mforth's: the whole Forth machine sits in callee-saved
registers, which is why a word that calls libc is the call and nothing else. That
decision, and what it costs, is in `docs/adr/0003-forth-machine-in-callee-saved-registers.md`.

Note that `rsp` appears in the preserved group. A function may move it while it runs, but
it must put it back — that is what `ret` depends on.

## Stack alignment

`rsp` must be a multiple of 16 at the moment you execute a `call`. The `call` then pushes
an 8-byte return address, so a function finds itself 8 bytes out of alignment on entry and
is expected to fix that up.

```
    before libc's startup code calls main   rsp ≡ 0  (mod 16)
    the call pushes a return address        rsp ≡ 8
    main: sub rsp, 8                        rsp ≡ 0   ← and it never moves again
```

That single `sub rsp, 8` in `main` is the whole of mforth's alignment story. Because no
word pushes or pops on the machine stack, every `call printf` in every word is aligned
without doing anything about it.

Get this wrong and the failure is not immediate or obvious: libc routines use SSE
instructions that fault only on some inputs, so a misaligned stack can print correctly for
a long time and then crash in `printf` for no visible reason.

## Variadic calls

A variadic function such as `printf` needs to know how many vector registers the caller
used, and the ABI puts that count in `al`. Zero is a legal answer and the common one:

```
code_dot:
        mov     rsi, [DSP]              ; argument 2: the number to print
        add     DSP, 8
        mov     rdi, dot_format         ; argument 1: the format string
        xor     eax, eax                ; al = 0: no vector registers used
        call    printf
```

Leave `al` holding garbage and `printf` may go looking for floating-point arguments that
were never passed. `xor eax, eax` is two bytes and removes the whole question.

## The red zone

The 128 bytes immediately below `rsp` are the *red zone*: a leaf function may use them as
scratch without moving `rsp`, and the kernel will not put a signal frame there. mforth
does not use it, and any word that decides to needs to remember that a `call` — libc's or
its own — makes that area fair game again.
