# B · The stack and calls

Read this before the exercises. It covers what this tier uses that the talk
didn't.

## The 16-byte rule

The System V convention asks one more thing of every call: at the moment of
the `call` instruction, `rsp` is a multiple of 16. The `call` itself then
pushes the return address, eight bytes, so every function starts with `rsp`
8 off a multiple of 16:

| Where | `rsp` ends in |
|-------|---------------|
| Just before the caller's `call` | `0` |
| At your function's first instruction | `8` |
| After `sub rsp, 8`, or one `push` | `0`, ready to call something |

So a function that calls nothing can ignore the rule, and one that calls
something has to move `rsp` by 8, or 24, or any odd number of eight-byte
steps, before it does.

Break the rule and, most of the time, nothing happens. Some library
functions use instructions that need their data at an address that's a
multiple of 16, such as `movaps`, and keep that data on the stack: those
crash. In this lab's image, run through Rosetta on an Apple Silicon Mac,
`printf` didn't crash on a misaligned stack even when it was handed a
double. That's luck: whether it crashes depends on the libc and the
processor, and any of them is entitled to. The tests check `rsp` at every
call they can see, and fail the ones that break the rule.

## Two ways to get there

```x86asm
        sub     rsp, 8          ; 8 bytes nobody uses, just for the alignment
        ; ...
        add     rsp, 8          ; give them back before ret
```

```x86asm
        push    rbx             ; keeps rbx, and moves rsp by 8 as well
        ; ...
        pop     rbx
```

Every push and every `sub` has to be undone before `ret`, in the opposite
order, because `ret` jumps to whatever is on top of the stack. Count pushes:
one aligns, two don't, three do.

## Who keeps what, in practice

| Kind | Registers | What it means for you |
|------|-----------|-----------------------|
| caller-saved | `rax rdi rsi rdx rcx r8 r9 r10 r11`, every `xmm` | Gone after any `call`. Yours to use freely, and nothing you call promises to leave them alone |
| callee-saved | `rbx rbp r12 r13 r14 r15` | Survive every `call`. But your caller is relying on them too: `push` one before you use it, `pop` it before you return |

So a value needed after a call goes in a callee-saved register, or on the
stack. A function that calls nothing can do all its work in caller-saved
registers and save nothing.

## Calling a function by name

```x86asm
        extern  puts            ; defined somewhere else: libc, or the test

        mov     rdi, msg        ; arguments in rdi, rsi, rdx, rcx, r8, r9
        call    puts            ; the result comes back in rax
```

`extern` tells nasm that the name is defined in another file, and the link
finds it. The lab links with `-no-pie`, like mforth, which is what lets the
call be written with the bare name, and the address of `msg` be loaded with
`mov`.

## Calling printf: al

`printf` takes any number of arguments, so it can't know which registers
hold one. A function like that, *variadic*, reads `al` to find out how many
of its arguments are in `xmm` registers. For integers and strings only, that
is none:

```x86asm
        xor     eax, eax        ; al = 0, and the rest of rax with it
        call    printf
```

## In gdb

| Type | What it shows |
|------|---------------|
| `p/x $rsp` | `rsp` in hex. At a `call` that keeps the rule, the last digit is 0 |
| `x/4gx $rsp` | The top four cells of the stack, newest first |
| `x/4ga $rsp` | The same, with each address named by the function it is in: a return address shows up as `<main+42>` |
| `ni` | Run one instruction, but a `call` as a whole. `si` follows the call in |
| `finish` | Run until the current function returns, and show what it returned |
