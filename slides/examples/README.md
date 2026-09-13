# slides/examples/

Five small assembly sources the x86-64 deck quotes. Every line on a slide is
a line from a file here, and the output on a slide is what the program
actually printed.

| File | What it shows |
|------|---------------|
| `exit-syscall.asm` | The smallest program there is: three instructions that ask the kernel to end the process |
| `hello-syscall.asm` | Printing with the `write` syscall, no libc. `_start`, and `exit` to end the process |
| `hello-libc.asm` | Printing with `call puts`, returning from `main`. Linked the way mforth is linked |
| `rmw-x86.asm` | `add [rax], rbx`: read, add and write back a memory cell in one instruction |
| `rmw-arm64.s` | The same work on arm64, where it takes `ldr`, `add`, `str` |

`exit-syscall.asm` comes first and stands alone: it is the whole shape of a
program with nothing in it. After that the files pair up, and the deck shows
each pair side by side: the syscall register convention against the System V
call convention, and one CISC instruction against three RISC ones.

## Building

The four x86-64 programs build in the container that builds mforth:

```sh
docker exec -w /Workspace/mforth/slides/examples nasm-docker-amd64 make run
```

`make` builds them, `make run` builds and runs all four, and `make clean`
removes what was built. The top-level `Makefile` does not look here: nothing
in `slides/` is part of `make` or `make test`.

`rmw-arm64.s` is not in `all` and is never linked. It is an arm64 source,
kept to be read next to `rmw-x86.asm`, and it assembles on the macOS host,
where clang is an arm64 compiler:

```sh
cd slides/examples && make rmw-arm64.o
```

## What they print

Recorded from `make run` in `nasm-docker-amd64`, NASM 3.01 and clang 21.1.8.
All four exit with status 0.

```
$ ./exit-syscall
$ echo $?
0

$ ./hello-syscall
Hello from a syscall

$ ./hello-libc
Hello from libc

$ ./rmw-x86
cell = 40
cell = 42
```

`rmw-x86` prints the cell before and after the addition, so the slide can
show that the one instruction really did read it, add to it, and write it
back.
