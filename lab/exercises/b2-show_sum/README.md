# B2 · show_sum

Print two numbers and their sum with `printf`.

```c
void show_sum(long a, long b);
```

`show_sum(2, 3)` prints `2 + 3 = 5` and a newline. In C it would be one
line:

```c
printf("%ld + %ld = %ld\n", a, b, a + b);
```

| What | Where it arrives | Where `printf` wants it |
|------|------------------|-------------------------|
| The format | | `rdi` |
| `a` | `rdi` | `rsi` |
| `b` | `rsi` | `rdx` |
| `a + b` | | `rcx` |
| How many arguments are in `xmm` registers | | `al` |

The format is in the file already, labelled `format`.

The file is `lab/exercises/b2-show_sum/show_sum.asm`.

```sh
./check b2
```

```sh
./debug b2
```

The test catches what `printf` would have printed, and checks `al` and `rsp`
at the moment of the call. In gdb, `ni` runs a `call` as a whole, and
`p $rdi` and the rest show what each argument register holds just before
it.

<details>
<summary>Hint 1: the order of the moves</summary>

Every argument moves up one register, and each register is both a source
and a destination. `mov rsi, rdi` first would put `a` where `b` was, before
`b` had gone anywhere. Start with the last argument and work back to the
first.

</details>

<details>
<summary>Hint 2: a + b without losing a or b</summary>

`add` leaves its answer in its first operand. Copy one of them into `rcx`
first and add the other to that. Or let `lea rcx, [rdi + rsi]` work the sum
out as if it were an address: it reads no memory, and changes neither
`rdi` nor `rsi`.

</details>

<details>
<summary>Hint 3: al</summary>

`printf` takes any number of arguments, so it doesn't know which registers
hold one. `al` tells it how many `xmm` registers do, and here none do.
`xor eax, eax` makes it 0: writing `eax` clears all of `rax`.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
show_sum:
        sub     rsp, 8                  ; to a multiple of 16
        ; a + b in rcx
        ; b in rdx
        ; a in rsi
        ; the format in rdi
        ; al = 0
        call    printf
        add     rsp, 8
        ret
```

</details>

## When it passes

Take out the instruction that sets `al` and run the test again. What was in
`al` at the call, and where did that number come from? `./debug b2` and
`p $rax` just before the call will tell you.
