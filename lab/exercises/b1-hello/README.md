# B1 · hello

Print a line by calling `puts`, from the C library.

```c
void hello(void);
```

`hello` prints `Hello, world!` and a newline. `puts` does the printing:

```c
int puts(const char *s);
```

| What | Where it is |
|------|-------------|
| `s`, the address of the string, for `puts` | `rdi` |

`puts` adds the newline itself, so the string in the file ends in a zero byte
and nothing else. The file already has it, labelled `msg`, and already says
`extern puts`, which tells nasm that the name is defined somewhere else.

Read the tier notes first if you haven't: this exercise is mostly the
16-byte rule.

The file is `lab/exercises/b1-hello/hello.asm`.

```sh
./check b1
```

```sh
./debug b1
```

The test catches what `hello` prints instead of letting it reach the screen,
and checks `rsp` at the moment of the call. Two commands are worth knowing
here:

| Type | What it does |
|------|--------------|
| `ni` | Run one instruction, but a `call` as a whole (*next instruction*). `si` would follow it into `puts` |
| `p/x $rsp` | Print `rsp` in hex. At a call that keeps the rule, its last digit is 0 |

<details>
<summary>Hint 1: the call</summary>

The address of the string goes in `rdi`, then `call puts`. With `-no-pie`,
`mov rdi, msg` is all it takes to load the address: `msg` is a number the
linker knows.

</details>

<details>
<summary>Hint 2: the second case fails</summary>

Run `./debug b1` and `p/x $rsp` at the first instruction. It ends in 8: the
call that came into `hello` pushed its return address. Move `rsp` down 8
more before `call puts`, and give the 8 back before `ret`, or `ret` jumps to
the wrong place.

</details>

<details>
<summary>Hint 3: the shape of it</summary>

```x86asm
hello:
        ; rsp down 8, to a multiple of 16
        ; the address of msg in rdi
        call    puts
        ; rsp up 8, back where it was
        ret
```

</details>

## When it passes

Run `./debug b1` and, at the first instruction, type `x/a $rsp`. The eight
bytes `rsp` points at are an address, and gdb names the function it is in.
Whose is it, and what happens to it at `ret`?
