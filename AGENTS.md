# AGENTS.md

## What is this

mforth is a 64-bit indirect-threaded-code (ITC) Forth for Linux/x86_64, written in NASM assembly. It is the worked example for a presentation on Forth, so the code is written to be read aloud and explained. Binding design constraints are in `docs/architecture/design-goals.md`.

## Stack

| Piece | Choice |
|-------|--------|
| Language | x86_64 assembly, NASM syntax |
| Target | Linux/x86_64 |
| Threading model | Indirect threaded code (ITC) |
| C runtime | libc, linked dynamically |
| Assembler / linker | `nasm -f elf64`; linked with `clang -no-pie`. No `gcc` in the container |
| Build | Make |
| Build environment | Docker container `nasm-docker-amd64`, repo mounted at `/Workspace/mforth`. The host is macOS/arm64 and cannot build |

## Directory index

| Path | What's there |
|------|-------------|
| `src/` | Assembly sources. nasm is invoked on `src/mforth.asm` alone; the rest arrive through `%include`. |
| `include/` | `.inc` files of macros and constants. `include/mforth.inc` holds the register names, the sizes of the two stacks, the input buffer and the dictionary, and the NEXT macro; `include/dictionary.inc` holds the header layout and the two macros that define a word. A constant that sets the size of one of those regions goes in `include/mforth.inc`, not beside the storage it sizes. |
| `lib/` | `lib/prelude.f`, the words written in Forth. The shell pipes it into mforth ahead of the terminal; nothing in the interpreter loads a file. |
| `tests/` | `tests/run.sh`, one `.expected` file per test, and the `.f` file feeding it. |
| `docs/` | Durable project context. Sub-folder layout below shows where each kind of doc goes. |
| `slides/` | The two intro decks shown before the main talk, and the reveal.js they run on. Nothing here is built: `make` and `make test` ignore it. See `slides/README.md`. |

```
docs/
├── system/         ← what the code does today (updated as code changes)
├── architecture/   ← what the system must do (updated when rules change)
├── adr/            ← architecture decisions (immutable once shipped)
├── reference/      ← long-form rationale (append-only)
└── working-notes/  ← research; NOT authoritative — rules live in architecture/ + adr/
```

## Commands

| What | Command |
|------|---------|
| Run anything in the build environment | `docker exec -w /Workspace/mforth nasm-docker-amd64 sh -c '<command>'` |
| Build | `make` |
| Build, then run the tests | `make test` |
| Build, then run mforth | `make run` |
| Delete the build output | `make clean` |
| Assemble | `nasm -f elf64 <file>.asm -o <file>.o` |
| Link | `clang -no-pie <file>.o -o <name>` |

The Makefile invokes nothing but nasm and clang, so every `make` command needs the container prefix above. See `docs/adr/0002-keep-the-container-out-of-the-makefile.md`.

The container is not auto-started (restart policy `no`). If `docker exec` fails because Colima or `nasm-docker-amd64` is not running, ask the developer before starting either. Do not run `colima start` or `docker start` unprompted.

## Gotchas

- `-no-pie` is load-bearing for readability, not just packaging. In a non-PIE executable the linker synthesizes a PLT stub for `puts`, so `call puts` assembles and links as written, and a string's address is just `mov rdi, msg`. Under clang's default PIE both break: the call fails with `relocation R_X86_64_PC32 ... can not be used when making a PIE object` and must be written `call puts wrt ..plt`, and the address must become `lea rdi, [rel msg]`. Never "fix" a PIE relocation error by adding `wrt ..plt` — add `-no-pie` to the link instead.
- It is PIE that breaks the simple syntax, not dynamic linking. `clang -static` also works, because it implies non-PIE; it was the original choice here, dropped in favour of `-no-pie` because the flag names the actual constraint. See `docs/adr/0001-link-non-pie.md`.
- Standard output is a pipe under `docker exec` without `-t`, so nothing that buffers it flushes on its own. `main` calls `setvbuf` for line buffering before it prints anything. Do not remove that call: without it an interactive session shows nothing at all until Ctrl-D, and then prints the whole session at once. See `docs/system/build-and-tests.md`.
- The `cat` in the container is the Rust uutils one, not GNU. It holds what it reads from the terminal when its output is a pipe, so `cat lib/prelude.f - | ./build/mforth` answers a typed line only when the next line is typed. Neither `-u` nor `stdbuf` reaches it, because it is not libc stdio. `make run` feeds the terminal half through `sed -u ''` instead. `make test` is unaffected: it compares the output after mforth has ended.
