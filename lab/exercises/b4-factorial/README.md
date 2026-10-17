# B4 · factorial

Return `n!`, the recursive way: by calling `factorial` itself.

```c
long factorial(long n);
```

| What | Where it is |
|------|-------------|
| `n` | `rdi` |
| `n!`, which you return | `rax` |

`n!` is `1 * 2 * ... * n`, and `0!` is 1. A loop would do, but the point
here is the call: `factorial` returns 1 when `n` is 0 or 1, and otherwise
`n` times whatever `factorial(n - 1)` returns. The test goes up to 20, the
largest `n` whose factorial fits in 64 bits.

The file is `lab/exercises/b4-factorial/factorial.asm`.

```sh
./check b4
```

```sh
./debug b4
```

gdb stops at every call to `factorial`, the ones it makes itself included.
`c` goes on to the next one.

<details>
<summary>Hint 1: the case that stops it</summary>

Compare `rdi` with 1 first. If it is 1 or less, put 1 in `rax` and return:
no call at all. Use a signed jump, so that nothing negative slips past.

</details>

<details>
<summary>Hint 2: where n survives the call</summary>

After the call you still need `n`, to multiply by. But `rdi` is
caller-saved, and the call you make changes it: it is where `n - 1` goes.

Keep `n` on the stack. `push rdi` before the call, `pop rdi` after it, and
every call deeper down does the same with its own `n`. Or copy `n` into a
callee-saved register such as `rbx`: then that register's old value has to
go on the stack instead, for whoever called you. Either way, `n` ends up on
the stack.

</details>

<details>
<summary>Hint 3: the 16-byte rule</summary>

One push of 8 bytes takes `rsp` from 8 off a multiple of 16 to on one. That
is the alignment the call needs, with nothing else added.

</details>

<details>
<summary>Hint 4: the shape of it</summary>

```x86asm
factorial:
        ; if n <= 1: rax = 1, ret
.recurse:
        ; keep n
        ; rdi = n - 1
        call    factorial
        ; get n back
        imul    rax, rdi                ; n * (n - 1)!
        ret
```

</details>

## When it passes

Run `./debug b4`, and make the breakpoint stop only when `n` is 15, five
calls down from the test's `factorial(20)`:

```text
cond 1 $rdi == 15
c
```

Then `x/12ga $rsp`. Every pair of cells is one call still waiting for its
answer: the address it returns to, in `factorial`, and the `n` it kept.
Where does the list end?
