# What mforth would look like on macOS/arm64

> **Working note — not authoritative.** Binding rules live in `architecture/` and `adr/`.
> Nothing here is a rule until it's promoted — however settled it reads.

Status: Research note

Portability is an explicit non-goal (`docs/architecture/design-goals.md`), and the target
stays Linux/x86_64. This note exists because the development machine is macOS/arm64 and
the question comes up: what would have been different? Everything below was built and run
on that machine as a sketch — `mforth-on-macos-arm64.S`, next to this note — which prints
the same output as the real thing, so these are measurements rather than predictions. The
sketch is not part of the build: it is assembled by hand with a single `clang
mforth-on-macos-arm64.S`, on a Mac, and it is here to be read rather than maintained.

## The short version

arm64 is the better *machine* for a threaded Forth. macOS/Mach-O is the worse *platform*
for a readable one. The register choices get easier and mostly stop being choices; the
toolchain and the ABI take back what the instruction set gives.

## The register assignment stops being interesting

AAPCS64 gives ten callee-saved registers, `x19`–`x28`, on top of eight argument registers
`x0`–`x7` and seven scratch registers `x9`–`x15`. Reserving three for the Forth machine
costs nothing anyone would notice:

```
    #define IP   x19
    #define DSP  x20
    #define RSP  x21
    #define W    x9
```

W can be a scratch register for the same reason it is `rax` on x86-64: it is dead the
moment `docol` has read it. The difference is what is left over. On x86-64, reserving
three of six preserved registers is a real decision with consequences — that is what
`docs/adr/0003-forth-machine-in-callee-saved-registers.md` is about. Here, seven preserved
registers remain, so a word could keep a local value across a libc call, which the x86-64
version cannot afford. The ABI simply stops dictating the layout.

Three registers are off the table, none of which a Forth wants anyway: `x18` is reserved
on Apple platforms, `x16` and `x17` can be overwritten by linker-inserted veneers across a
call, and `x29` is the frame pointer Apple's ABI expects to be maintained for backtraces.
`x30` is the link register.

## NEXT is still three instructions, but the indirection is visible

ARM is load/store, so there is no branch-through-memory. The code field has to be loaded
before it can be jumped to:

```
    ldr     W, [IP], #8             // fetch the token, step IP past it
    ldr     x10, [W]                // the word's code field
    br      x10                     // and into its machine code
```

The post-indexed load does exactly what `lodsq` does — fetch and advance in one
instruction — but on any register, with no fixed-register requirement and no direction
flag to remember. So the temptation that pulls x86 Forths into putting IP in `rsi`
(choice 1 in `docs/reference/register-choices-in-a-forth.md`) is just an addressing mode
here, with no cost attached.

Against that, x86-64's `jmp [W]` becomes two instructions. Three either way — and
arguably the arm64 form teaches indirect threaded code better, because both loads are
written out. The word "indirect" is on the page instead of hidden in a pair of brackets.

## The argument for hijacking the machine stack evaporates

Pre- and post-indexed addressing give push and pop on *any* register:

```
    str     IP, [RSP, #-8]!         // push: one instruction
    ldr     IP, [RSP], #8           // pop:  one instruction
```

On x86-64, `push`/`pop` are one instruction only for `rsp`, and everything else is a `sub`
plus a `mov`. That asymmetry is the main argument for putting the data stack or the return
stack on the machine stack (choices 2 and 3 in the same doc). On arm64 there is no
asymmetry, so both arguments are gone: a stack of your own is exactly as cheap as the
machine's. `stp`/`ldp` push and pop *pairs* in one instruction, which lines up neatly with
the 16-byte alignment rule. `docol` becomes three instructions and EXIT becomes two.

## Alignment stops being a chore and becomes a constraint

`bl` puts the return address in `x30`, not on the stack, so a call never disturbs SP. The
sketch contains no alignment instruction anywhere — no equivalent of `main`'s
`sub rsp, 8` — and runs correctly. In exchange, Darwin arm64 wants SP 16-byte aligned
whenever it is used as a base register, not merely at call boundaries, so a word that does
touch SP has to move it in multiples of 16.

## PIE stops being a choice

`docs/adr/0001-link-non-pie.md` is moot here. Non-PIE is not available:

```
    ld: warning: -no_pie ignored for arm64*
```

And there is no simple absolute-address form to protect. Every address is an `adrp`/`add`
pair:

```
    adrp    x0, dot_format@PAGE
    add     x0, x0, dot_format@PAGEOFF
```

`adr` is a single PC-relative instruction and does assemble for a label in the same
section, but it reaches only ±1 MB and fails outright across sections — `adr x0, banner`
pointing into `__TEXT,__cstring` is rejected with *unknown AArch64 fixup kind!*. So the
gotcha in the root `AGENTS.md` has no analogue: on x86-64 there is a readable form worth
defending with a link flag, and here there is only the one form, everywhere, two
instructions each time.

## Variadic calls are the one real regression

Apple's arm64 ABI passes **all** variadic arguments on the stack. `.` cannot put the
number in `x1` the way the x86-64 version puts it in `rsi`. Doing so does not crash — it
prints `0` instead of `42`, verified. The word has to build a stack frame for the
argument:

```
code_dot:
    ldr     x1, [DSP], #8
    sub     sp, sp, #16             // Apple arm64: variadic args go on the stack
    str     x1, [sp]
    adrp    x0, dot_format@PAGE
    add     x0, x0, dot_format@PAGEOFF
    bl      _printf
    add     sp, sp, #16
    NEXT
```

Eight instructions instead of six, and — worse for the presentation — the word now touches
SP, which breaks the invariant ADR 0003 leans on. Two consolations: the `xor eax, eax`
vector-count line disappears, because no ARM ABI has that rule; and the pressure pushes
toward giving Forth its own number formatting (`<# # #S #>`, pictured numeric output) and
calling non-variadic `fputs`, which is what a Forth does anyway.

Worth noting that this is Apple's deviation, not ARM's. On aarch64-linux the same call
passes its arguments in `x1` and `x2` and tail-calls `printf`. A Linux/aarch64 target
would keep every arm64 win in this note and pay none of this cost.

## The toolchain is where most of the cost lands

NASM does not exist for ARM, so the assembler becomes clang's own with GNU-flavoured
syntax. Naming the file `.S` runs it through the C preprocessor, which gives `#define IP
x19` in place of `%define` and `.macro`/`.endm` in place of `%macro`. Mach-O then charges
for a few things NASM gave away:

| | Linux/x86_64, NASM | macOS/arm64 |
|---|---|---|
| libc symbols | `printf` | `_printf` — leading underscore on everything |
| BSS | `resb 65536` with a label after it | `.zerofill __DATA,__bss,_data_stack,65536,4` |
| top of a stack region | a label | base plus the size: `add DSP, DSP, #16, lsl #12` |
| taking an address | `mov rdi, msg` | `adrp` + `add`, two instructions, always |

None of that is hard. All of it is one more thing to explain in a talk whose subject is
Forth.

## Resolved

- The register assignment would be `IP`=`x19`, `DSP`=`x20`, `RSP`=`x21`, `W`=`x9`, and
  the reasoning behind ADR 0003 would not need to be made — with ten callee-saved
  registers the ABI does not constrain the choice.
- Both Forth stacks would still live in regions of their own, and for a stronger reason
  than on x86-64: indexed addressing makes push and pop one instruction on any register,
  so there is nothing left to gain by taking SP.
- `NEXT` would stay three instructions, and would show the double indirection more
  plainly than the x86-64 version does.
- The x86-64 choice stands, but on platform grounds — NASM's syntax, absolute addressing
  under `-no-pie`, and printf taking its arguments in registers — not architectural ones.

## Open questions

- Should pictured numeric output come earlier regardless of target? It removes the only
  variadic libc call in the system, which would make the two platforms behave the same.
- Would a Linux/aarch64 target be strictly better than both — GNU as, a real `.bss`,
  variadic arguments in registers, and every arm64 instruction-set win? The measurements
  here say probably, but nothing was built to check.
- Building for arm64e would put pointer authentication on the code-field branch (`braa`
  rather than `br`). Regular arm64 binaries do not need it, but it is worth knowing that
  the presentation's central instruction is the one PAC would touch.
