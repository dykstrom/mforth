# D · Debugger puzzles

Read this before the puzzles. They're about reading code, not writing it.

## The puzzle

Each phase is a function you have no source for:

```c
int phase1(const char *input);
```

It returns 1 if it accepts the input and 0 if not. Your file,
`exercises/d1-phase1/phase1.asm`, holds the input: one string, empty for
now. The test hands it to `phase1`, and passes when `phase1` returns 1.

So the loop is: look inside `phase1` with gdb until you know what it wants,
write that between the quotes, and run `./check d1`. A wrong guess costs
nothing. The phase says *rejected*, and you look again.

```sh
./debug d1
```

gdb stops at the first instruction of `phase1`. There's no source to show,
so the middle window shows the machine code instead, with an arrow at the
next instruction.

## Reading machine code in gdb

| Type | What it shows or does |
|------|-----------------------|
| `x/20i $pc` | The next 20 instructions, from where the program has stopped |
| `disas` | The whole function you're in, as far as the next label |
| `ni` | Run one instruction. A `call` runs to its end: *next instruction* |
| `si` | Run one instruction. A `call` goes into the function: *step instruction* |
| `finish` | Run to the end of this function, and stop in the one that called it |
| `b *0x401308` | Stop at that address. The `*` says it's an address, not a name |
| `c` | Continue, to the next breakpoint or the end |
| `info registers` | Every integer register. `info registers rdi rsi` for just those |
| `p $rax` | One register, as a number. `p/x $rax` in hex, `p $eax` the low half, signed |
| `x/s 0x402040` | The string at an address. `x/s $rdi` the one a register points at |
| `x/4gx $rsp` | Four 8-byte cells (*g*iant) in hex. `x/4gd` the same cells as signed numbers |

Use `ni`, not `si`, to get past a `call strcmp`. `si` follows the call into
libc, which has no source either and goes on for a while. If you end up
there anyway, `finish` brings you back.

`disas` stops at a label. The puzzle's loops have labels such as
`phase2.next`, so `disas` may show you only the start of the function.
`x/30i phase2` shows thirty instructions from the start, whatever the labels
say. The labels are worth reading too: a jump to `<phase2.wrong>` is the
phase giving up.

## Numbers that are addresses

```text
movabs rsi,0x402040
```

`movabs` is `mov` with a full 64-bit number. Nothing says whether a number
is an address, but a number like `0x402040` almost always is one. This
program's code and constants sit just above `0x400000`, and the stack far
above that, at addresses that start `0x7ff`. `x/s 0x402040` shows what's
there.

The addresses move a little when your input changes length, because your
string sits among the puzzle's own constants. Take them from your own
listing, not from someone else's.

## A method

1. **Find the calls.** `x/30i $pc` and look for `call`. A call to a libc
   function you know, such as `strcmp`, `sscanf` or `strlen`, tells you what
   kind of input the phase wants.
2. **Look at the arguments.** Just before the `call`, the arguments are in
   `rdi`, `rsi`, `rdx`, `rcx`, `r8` and `r9`. Stop on the `call` with
   `b *address` and `c`, then `info registers` and `x/s`.
3. **Find the comparison that decides.** Every way to fail is a `cmp` or a
   `test` followed by a jump to the same place. Read what each one compares.
4. **Work backwards.** From a `cmp`, follow the registers it compares back up
   the listing to where they were loaded. That is what your input has to
   make true.

Step through with `ni` and watch which jump is taken. A phase rarely hides
its answer: it compares against it.
