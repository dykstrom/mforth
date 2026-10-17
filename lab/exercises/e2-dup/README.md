# E2 · DUP and SWAP

Write two words that rearrange the data stack.

```text
DUP  ( n -- n n )        2 DUP    leaves  2 2
SWAP ( n1 n2 -- n2 n1 )  2 3 SWAP leaves  3 2
```

| What | Where it is |
|------|-------------|
| DSP, the address of the top item | `r12` |
| The item under it | `[r12 + 8]` |

`rax` and `rdx` are free to use. Each word ends with `jmp next`, which is
already there.

The file is `lab/exercises/e2-dup/dup.asm`. It holds the whole Forth so far,
with NEXT done: that's exercise E1's answer. DUP and SWAP are at the labels
`dup` and `swap`, at the end. Until they're written, both leave the stack as
they found it.

```sh
./check e2
```

```sh
./debug e2
```

gdb stops at `dup`. To stop at SWAP too, type `b swap` before the first `c`.

If gdb says the breakpoint has two locations, 1.1 and 1.2, that's because
libc has a function called `dup` too. The test never calls libc's, so every
stop is at yours.

<details>
<summary>Hint 1: a push</summary>

LIT, higher up in the file, ends with a push. Move DSP down one cell, then
write into the cell it now points at:

```x86asm
        sub     DSP, 8
        mov     [DSP], rax
```

DUP is a push of the item that's already on top. Read that item before DSP
moves.

</details>

<details>
<summary>Hint 2: SWAP needs two registers</summary>

x86-64 has no instruction that copies memory to memory. Read both items into
registers, `[DSP]` into one and `[DSP + 8]` into the other, then write each
one back where the other was. DSP doesn't move: the stack holds as many items
as before.

</details>

## When it passes

Run `./debug e2`, type `b swap`, and `c` until gdb stops at `swap` in the case
`LIT 2 LIT 3 SWAP BYE`. Look at the two items:

```text
x/2gd $r12
```

The top one, 3, comes first, because it's at the lower address. Step through
SWAP with `si` and look again.
