# E3 · +

Write `+`: take two numbers off the data stack, and leave their sum.

```text
+ ( n1 n2 -- n3 )        2 3 +  leaves  5
```

| What | Where it is |
|------|-------------|
| DSP, the address of the top item, n2 | `r12` |
| n1, the item under it | `[r12 + 8]` |

The file is `lab/exercises/e3-plus/plus.asm`. It holds the whole Forth so
far, with NEXT, DUP and SWAP done. `+` is at the label `plus`, at the end.
Until it's written, it leaves both numbers where they are.

```sh
./check e3
```

```sh
./debug e3
```

gdb stops at `plus` each time a thread reaches `+`.

<details>
<summary>Hint 1: a pop</summary>

A pop is a push backwards: read the item DSP points at, then move DSP up a
cell.

```x86asm
        mov     rax, [DSP]
        add     DSP, 8
```

After that, DSP points at n1.

</details>

<details>
<summary>Hint 2: adding into memory</summary>

`add` can take a memory operand as its destination. `add [DSP], rax` reads
the cell, adds `rax` to it, and writes the sum back, all in one instruction.

</details>

<details>
<summary>Hint 3: three instructions</summary>

Pop n2, then add it into n1 where n1 stands. The sum is then the top of the
stack, and nothing else needs to move. With `jmp next`, that's four lines.

</details>

## When it passes

Compare your `+` with the one in the talk's slide "Forth's +". It's
mforth's, from `src/words.asm`, and it should be the same three
instructions. The only difference is the last line: mforth ends with the NEXT
macro, and this Forth with `jmp next`.

Then run `./debug e3`, and at the first stop look at the stack before and
after `si` three times:

```text
x/2gd $r12
```
