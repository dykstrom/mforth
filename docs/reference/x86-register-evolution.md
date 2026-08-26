# How the x86 registers grew from 8 bits to 64

Why one register has four names. Every assembly book has this picture; this is the
version that matters for reading mforth, where `rax`, `eax` and `al` all appear and
all mean the same register.

## The four generations

| CPU | Year | Width | What it added |
|---|---|---|---|
| 8008, 8080 | 1972, 1974 | 8 | The accumulator `A`, plus `B C D E H L`. The 8080 could use them in pairs — `BC`, `DE`, `HL` — as 16-bit addresses. |
| 8086 | 1978 | 16 | `AX BX CX DX`, each splitting into a high and a low byte (`AH`/`AL`), plus `SI DI BP SP`. |
| 80386 | 1985 | 32 | `EAX` … `EDI`. The `E` is for *extended*. |
| AMD64 (x86-64) | 2003 | 64 | `RAX` … `RDI`, plus eight brand-new registers `R8`–`R15`. |

The 8086 was designed so that 8080 assembly could be mechanically translated, which is
why `AX` is *`A` extended* and why it has separately addressable halves: Intel's own
translator mapped the 8080's `A B C D E H L` onto `AL CH CL DH DL BH BL`. Two more
widenings later, the accumulator of a 1972 calculator chip is still bits 0–7 of `RAX`.

## One register, four windows

`RAX`, `EAX`, `AX`, `AH` and `AL` are not five registers. They are five names for
overlapping slices of the same 64 bits:

```
┌───────────────────────────────────────────────────────────────────────┐
│                            RAX   (64 bits)                            │
├───────────────────────────────────┬───────────────────────────────────┤
│                                   │          EAX   (32 bits)          │
├───────────────────────────────────┼─────────────────┬─────────────────┤
│                                   │                 │    AX  (16)     │
├───────────────────────────────────┼─────────────────┼────────┬────────┤
│                                   │                 │ AH (8) │ AL (8) │
└───────────────────────────────────┴─────────────────┴────────┴────────┘
 63                               32 31             16 15     8 7      0
```

Write `AL` and you have changed the bottom byte of `RAX`. Read `RAX` afterwards and the
change is there. There is no copying and no conversion; the names simply say how many
bits of the one register an instruction touches.

`AH` is the odd one out — the only slice that does not start at bit 0. It exists because
the 8086 needed to pretend two 8-bit registers were one 16-bit register, and it survives
in `AH BH CH DH` alone.

## The full naming table

| 64 | 32 | 16 | low byte | high byte |
|---|---|---|---|---|
| `rax` `rbx` `rcx` `rdx` | `eax` … | `ax` … | `al` `bl` `cl` `dl` | `ah` `bh` `ch` `dh` |
| `rsi` `rdi` `rbp` `rsp` | `esi` … | `si` … | `sil` `dil` `bpl` `spl` | — |
| `r8` … `r15` | `r8d` … | `r8w` … | `r8b` … | — |

The byte names in the second and third rows are new in 64-bit mode and need a `REX`
prefix to encode. That prefix is also what makes `AH BH CH DH` unreachable: an
instruction can use `sil` or it can use `ah`, never both.

## The one rule that bites

Writing a **32-bit** name clears the upper 32 bits. Writing an **8- or 16-bit** name
leaves the rest of the register alone.

```
    mov     rax, -1         ; rax = 0xFFFFFFFFFFFFFFFF
    mov     eax, 10         ; rax = 0x000000000000000A   ← top half zeroed
    mov     al, 10          ; rax = 0xFFFFFFFFFFFFFF0A   ← top 56 bits kept
```

That is not a quirk to work around, it is a tool. `mov eax, 10` and `mov rax, 10` leave
the same value in `rax`, but the 32-bit form is shorter, so it is what you write when the
value fits. mforth does exactly this:

- `xor eax, eax` in `code_dot` — clears all 64 bits of `rax`, which is what `printf`'s
  variadic convention asks for.
- `mov edi, 10` in `code_cr` and `xor edi, edi` in `code_bye` — `putchar` and `exit` take
  a C `int`, and the zero-extension means `rdi` is correct as a whole register too.

## See also

- `docs/reference/x86-64-registers-and-the-abi.md` — what each of the sixteen registers
  is used for, and the rules for calling libc.
