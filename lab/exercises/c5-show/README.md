# C5 · print a double

Print a label and a double with `printf`.

```c
void show(const char *label, double x);
```

| What | Where it is |
|------|-------------|
| `label`, the address of a string | `rdi` |
| `x` | `xmm0` |

`show("pi", 3.14159)` prints one line:

```text
pi = 3.14
```

That is the C call `printf("%s = %.2f\n", label, x)`. Put the format in
`.rodata`, with `10` for the newline and a `0` to end it:

```x86asm
format: db      "%s = %.2f", 10, 0
```

The file is `lab/exercises/c5-show/show.asm`.

```sh
./check c5
```

```sh
./debug c5
```

The test catches what `show` prints instead of letting it reach the screen,
and compares it. It also checks the stack at the moment of the call: see
hint 3.

<details>
<summary>Hint 1: the arguments to printf</summary>

`printf` takes the format first, in `rdi`. That's where `label` is, so
`label` has to move to `rsi` first, and then the format can go in `rdi`.

`x` is `printf`'s first floating-point argument, which is `xmm0`. It's
already there.

</details>

<details>
<summary>Hint 2: al</summary>

`printf` takes any number of arguments, so it can't know from its own
declaration whether any are doubles. The caller says so in `al`: the number
of `xmm` registers that hold arguments. Here that's one. Leave `al` at 0 and
`printf` never looks at `xmm0`. It prints a number from its own memory
instead, which in this lab comes out as 0.00 every time.

</details>

<details>
<summary>Hint 3: the 16-byte rule</summary>

At every `call`, `rsp` must be a multiple of 16. The test's call into `show`
kept that rule, and then pushed eight bytes of return address, so inside
`show` `rsp` is 8 off. Subtract 8 before the call to `printf` and add it back
after.

The `printf` in this lab's libc happens to work either way, so the test
checks the rule itself. Elsewhere, a misaligned call can crash inside
`printf`.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
show:
        sub     rsp, 8                  ; align the stack
        ; rsi = label
        ; rdi = format
        ; al = 1
        call    printf
        add     rsp, 8
        ret
```

</details>

## When it passes

Change `mov eax, 1` to `xor eax, eax` and run `./check c5` to see what
`printf` prints when it doesn't know about `xmm0`. Then put it back.

Run `./debug c5`, step to the `call printf` with `si`, and type `p
$xmm0.v2_double[0]`. `x` is in `xmm0` before the call, unmoved since `show`
began. Step over the call with `ni` and print it again. Is it still there?
Should you count on that?
