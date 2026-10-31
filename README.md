# mforth

A 64-bit indirect-threaded-code (ITC) Forth for Linux/x86_64, written in NASM assembly,
and a self-paced x86-64 assembly lab built around it.

The repository holds three things:

- **mforth**, the Forth itself, in `src/`, `include/` and `lib/`. It began as the worked
  example for a talk on Forth, so the code is written to be read aloud and explained:
  clarity wins over cleverness, and performance, code size, standards compliance and
  portability are explicit non-goals. See
  [`docs/architecture/design-goals.md`](docs/architecture/design-goals.md) for the binding
  constraints.
- **The lab**, in [`lab/`](lab/): a morning of x86-64 assembly exercises, one function each,
  with a test, hints and a solution. It starts with integers and loops, and goes on through
  calls and the stack, floating point and debugger puzzles to building a small Forth of your
  own. See [`lab/README.md`](lab/README.md).
- **The slides**, in [`slides/`](slides/): the x86-64 deck that opens the lab, and the Forth
  deck from the earlier talk. See [`slides/README.md`](slides/README.md).

## Starting the lab

In GitHub Codespaces: on the repository page, choose **Code → Codespaces → Create codespace
on main**. The lab pages open in a browser tab and the terminal opens in `lab/`.

On your own machine, with Docker installed, run this from the repository root:

```sh
lab/docker-shell
```

It leaves you in a shell in `lab/`, with the lab pages at <http://localhost:8000/lab/>.
Start with tier 0 there. [`lab/README.md`](lab/README.md) has the details, including what
an Apple Silicon Mac needs for the debugger.

## Building mforth

You need `nasm` and `clang` on Linux/x86_64:

```sh
nasm -f elf64 <file>.asm -o <file>.o
clang -no-pie <file>.o -o <name>
```

If your platform is not Linux/x86_64, build inside a container instead. Any x86_64 Linux
image with `nasm` and `clang` will do; mount the repository into it and run the commands
above from the mounted directory:

```sh
docker run --rm -v "$PWD:/workspace" -w /workspace <image> \
    sh -c 'nasm -f elf64 <file>.asm -o <file>.o && clang -no-pie <file>.o -o <name>'
```

On an arm64 host, ask for an amd64 image (`docker run --platform linux/amd64 ...`) so the
assembled binary can also be run under emulation.

`-no-pie` is load-bearing for readability, not just packaging. In a non-PIE executable the
linker synthesizes a PLT stub for `puts`, so `call puts` assembles and links as written, and
a string's address is just `mov rdi, msg`. Under clang's default PIE both lines break: the
call fails with `relocation R_X86_64_PC32 ... can not be used when making a PIE object` and
has to be spelled `call puts wrt ..plt`, and the address has to become `lea rdi, [rel msg]`.

Adding `-static` also works, since it implies non-PIE, and yields a self-contained binary —
at roughly fifty times the size.

## Documentation

Project documentation lives in [`docs/`](docs/), split by what each kind of doc is for —
what the code does today (`system/`), what it must do (`architecture/`), and how the
decisions were reached (`adr/`, `reference/`, `working-notes/`).

[`docs/system/interpreter-walkthrough.md`](docs/system/interpreter-walkthrough.md) follows one
typed line from the terminal to the answer, and names the file that covers each part it passes
through. It is the place to start.

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
