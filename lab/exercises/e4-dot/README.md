# E4 · the dot

Write `.`: take the top number off the data stack and print it, followed by
a space. Then the thread for `2 3 + .` prints 5.

```text
. ( n -- )               2 3 + .  prints  5
```

| What | Where it is |
|------|-------------|
| DSP, the address of the top item | `r12` |
| The format to print it with, `"%ld "` | `dot_format`, at the end of the file |

The file is `lab/exercises/e4-dot/dot.asm`. It holds the whole Forth so far,
with NEXT, DUP, SWAP and `+` done. `.` is at the label `dot`, near the end.
Until it's written, it prints nothing and leaves the number on the stack.

```sh
./check e4
```

```sh
./debug e4
```

gdb stops at `dot` each time a thread reaches `.`.

<details>
<summary>Hint 1: printf's arguments</summary>

`printf(dot_format, n)`: the format's address goes in `rdi` and the number in
`rsi`. Pop the number straight into `rsi`. `mov rdi, dot_format`, without
brackets, puts the label's address in `rdi`.

</details>

<details>
<summary>Hint 2: al</summary>

`printf` takes any number of arguments, and reads `al` to learn how many of
them came in `xmm` registers. None did, so clear it before the call: `xor eax,
eax`.

</details>

<details>
<summary>Hint 3: what printf leaves alone</summary>

`printf` may change `rax`, `rcx`, `rdx`, `rsi`, `rdi` and `r8` to `r11`.
None of them matters here: NEXT loads `W` afresh. IP and DSP are in `rbx` and
`r12`, which `printf` has to give back unchanged. So the word is the pop, the
arguments, the call, and `jmp next`. Nothing needs saving.

</details>

<details>
<summary>Hint 4: the stack is already aligned</summary>

A call needs `rsp` to be a multiple of 16. `forth` made it one before the
first word ran, and no word moves it, so `call printf` works as it stands.
The test checks, and says so if `rsp` was off when `printf` was called.

</details>

## When it passes

Run `./debug e4`, and step with `ni` until the next line is the `call
printf`. `ni` is `si` that runs a call as one step, instead of going into the
function. Look at IP and DSP:

```text
p/x $rbx
p/x $r12
```

Then `ni` once more, over the call, and look at both again. They haven't
changed.

`p $rax` shows how `printf` left `rax`: 2, the number of characters it
printed. NEXT is about to write over it.
