# Register choices in a Forth implementation

A Forth machine wants a handful of values in registers, and x86-64 has sixteen — which
sounds like plenty until you notice how many the ABI has already claimed. This doc lays
out the choices, what each one buys, what it costs, and why mforth's answers are the dull
ones. The decision itself is recorded in
`docs/adr/0003-forth-machine-in-callee-saved-registers.md`; this is the longer argument
behind it.

## What a Forth wants in registers

| Value | What it does | Needed by |
|---|---|---|
| **IP** | Address of the next execution token in the thread. | Any threaded Forth. |
| **W** | The token `NEXT` jumped through, so the code entered can find its own body. | Indirect and direct threading. |
| **DSP** | Data stack pointer. | Everything. |
| **RSP** | Return stack pointer — Forth's own, not the machine's. | Everything with colon definitions. |
| *TOS* | Top data stack item, cached out of memory. | Optional, for speed. |
| *UP* | User-area pointer, for per-task variables. | Multitasking Forths. |

mforth needs the first four. The last two are optimizations it does not want.

## The budget

Sixteen registers, but the usable set is smaller than that. `rsp` belongs to the hardware.
Nine registers — `rax`, `rcx`, `rdx`, `rsi`, `rdi`, `r8`–`r11` — are destroyed by any
`call`, and six of those are the argument registers. That leaves six that survive a call:
`rbx`, `rbp`, `r12`, `r13`, `r14`, `r15`.

So the constraint is not *how many* registers there are. It is that a Forth calling libc
has exactly six places to keep a value that must live across a `call`, and it wants three
or four of them.

## Choice 1: put IP in `rsi` so `NEXT` can use `lodsq`

`lodsq` loads `[rsi]` into `rax` and adds 8 to `rsi` in one instruction, which turns
`NEXT` into two instructions instead of three:

```
    lodsq                   ; W = [IP], IP += 8
    jmp     [rax]           ; through the code field
```

**Gained.** One instruction and one line. It is the classic assignment, and it reads
beautifully — *if* the reader already knows what `lodsq` does.

**Lost.** `rsi` is caller-saved *and* it is argument 2, so every libc call needs IP saved
and restored around it, and no word can pass an argument in `rsi` while IP lives there.
`lodsq` also silently depends on the direction flag being clear — a precondition nothing
in the code states. And on any CPU built this century it is no faster than `mov` plus
`add`.

**mforth.** IP is `rbx`; `NEXT` is `mov`, `add`, `jmp`. Three instructions that need no
footnote.

## Choice 2: make the machine stack the data stack

**Gained.** The data stack operations become the machine's own: `push` and `pop`, one or
two bytes each, accelerated by the CPU's stack engine. You spend no register on DSP at
all — which mattered enormously on 32-bit x86, where there were only eight registers to
begin with. You also inherit the OS's guard page, so a runaway program segfaults cleanly
instead of quietly overwriting something.

**Lost.** Calling a C function stops being free. The ABI wants `rsp` 16-byte aligned at
every `call`, and the alignment now depends on how many items the *Forth program* happens
to have on the stack — something the implementation cannot know. Every word that calls
libc would have to align and restore:

```
    mov     r14, rsp
    and     rsp, -16                ; align, whatever the program left on the stack
    call    printf
    mov     rsp, r14                ; put the data stack back
```

That is a spare preserved register plus three instructions per call, which is worse than
the ceremony it was meant to avoid. On top of that, `push` and `pop` are no longer
available as scratch inside a primitive, and every debugger, profiler and backtrace now
reads the data stack as a call stack.

**mforth.** The data stack is a 64 KB `.bss` region with `DSP` = `r12` pointing at the top
item.

## Choice 3: make the machine stack the return stack

**Gained.** `>R` and `R>` become `push` and `pop`. Go one step further and let `call` and
`ret` *be* colon entry and exit, and IP and W disappear entirely — no inner interpreter at
all. That is subroutine threading, and it is what native-code Forths do.

**Lost.** It is no longer indirect threaded code, which is the one thing this
implementation exists to show. Alignment breaks the same way as in choice 2, because a
Forth-level `>R` pushes 8 bytes and leaves the stack odd for the next libc call. Forth's
return stack also holds loop indices and temporary saves, which would sit interleaved with
machine return addresses. And recursion depth becomes the OS's business rather than a
number you chose.

**mforth.** The return stack is its own `.bss` region with `RSP` = `r13`. `docol` and
`EXIT` are written out, four instructions each, and can be read aloud.

## Choice 4: cache the top of the data stack in a register

**Gained.** Fewer memory accesses in almost every primitive. `DUP` becomes one `mov`;
`+` never reloads its second operand.

**Lost.** Every primitive now has two possible homes for a value, so every word you write
afterwards has to maintain the invariant, and `( n1 n2 -- n3 )` no longer describes what
is in memory. It is the single most common Forth optimization and the single worst thing
you can do to a Forth you intend to explain.

**mforth.** No cache. The stack comment and the memory agree.

## Choice 5: keep nothing in registers

A Forth hosted in C, or one that must run on machines it has not met yet, keeps IP and
both stack pointers in a struct and loads them per primitive. Gained: portability, and no
ABI negotiation at all. Lost: speed, and the inner interpreter stops being three
instructions you can put on a slide.

## Where the two stacks can live

```
  Option A — each stack in its own region              (mforth)
      rsp    machine stack    libc's frames only; aligned once, never touched again
      DSP    .bss region      data stack
      RSP    .bss region      return stack

  Option B — the data stack IS the machine stack       (fig-Forth, jonesforth)
      rsp    machine stack    data stack
      RSP    .bss region      return stack

  Option C — the return stack IS the machine stack     (native-code Forths)
      rsp    machine stack    return stack; call and ret are colon entry and exit
      DSP    own region       data stack, top item or two cached in registers
```

## What other Forths do

| Forth | IP | W | Data stack | Return stack | Why that works for them |
|---|---|---|---|---|---|
| 8086 fig-Forth, and jonesforth after it | `si` | `ax` | `sp` (machine) | `bp` | They talk to the kernel directly and never link libc, so caller-saved costs nothing and `sp` is free to take. |
| gforth | register variable | — | register variable | register variable | Written in C with GNU extensions; pins its machine into explicit register variables, caches TOS where a machine has registers to spare, and leaves the C stack to C. A performance project. |
| VFX Forth, SwiftForth | none | none | dedicated register | `rsp` (machine) | Native-code compilers: `call`/`ret` are colon entry and exit, so there is no IP to keep anywhere. |
| 6502 Forths | zero page | zero page | zero page | the hardware's 256-byte stack | Fewer registers than a Forth needs, so almost everything lives in memory and `NEXT` is a subroutine. |

The pattern is that the layout follows what the Forth talks to and what it is optimizing
for. Raw syscalls leave `rsp` free. libc pushes you into the callee-saved registers.
Native code makes the machine stack the return stack. A CPU with three registers puts
everything in memory.

## What decided it here

Simplicity, as required by `docs/architecture/design-goals.md`. mforth chose libc over
syscalls, and that one decision picked the registers: the Forth machine goes in
callee-saved registers, both stacks get regions of their own, and `main` aligns `rsp` once
so no word has to think about it.

What that costs is worth saying plainly. Three preserved registers are reserved for the
interpreter, leaving `rbp`, `r14` and `r15` plus the volatiles for anything a word needs
locally. `NEXT` is three instructions rather than two. Every stack operation is a `sub`
or `add` and a `mov` instead of a `push` or a `pop`. Nothing here is fast. Everything here
can be read out loud.

## See also

- `docs/adr/0003-forth-machine-in-callee-saved-registers.md` — the decision.
- `docs/reference/x86-64-registers-and-the-abi.md` — the ABI rules the choices answer to.
- `docs/system/inner-interpreter.md` — what the code does with them today.
