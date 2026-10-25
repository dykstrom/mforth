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
| `slides/` | The x86-64 deck that opens the lab, the Forth deck from the earlier talk, and the reveal.js they run on. Nothing here is built: `make` and `make test` ignore it. See `slides/README.md`. |
| `lab/` | The self-paced assembly lab: exercise pages, `./check` and `./debug`. Runs in its own image, not in `nasm-docker-amd64`, and `make` ignores it. See `lab/README.md`. |
| `.devcontainer/` | The lab's image, for Codespaces and for `lab/docker-shell`. |

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
| Build every lab solution and run its test | `docker run --rm --platform linux/amd64 -v "$PWD:/workspace" -w /workspace/lab x86-lab ./check --solutions` |

The Makefile invokes nothing but nasm and clang, so every `make` command needs the container prefix above. See `docs/adr/0002-keep-the-container-out-of-the-makefile.md`.

The lab runs in its own image, `x86-lab`, which `lab/docker-shell` builds from `.devcontainer/Dockerfile`. A `docker run` of it does not need `nasm-docker-amd64`. Docker mounts only directories under the home directory, so a scratch build must go in `lab/build/`, which git ignores, and not in `/tmp`.

The container is not auto-started (restart policy `no`). If `docker exec` fails because Colima or `nasm-docker-amd64` is not running, ask the developer before starting either. Do not run `colima start` or `docker start` unprompted.

## Gotchas

- `-no-pie` is load-bearing for readability, not just packaging. In a non-PIE executable the linker synthesizes a PLT stub for `puts`, so `call puts` assembles and links as written, and a string's address is just `mov rdi, msg`. Under clang's default PIE both break: the call fails with `relocation R_X86_64_PC32 ... can not be used when making a PIE object` and must be written `call puts wrt ..plt`, and the address must become `lea rdi, [rel msg]`. Never "fix" a PIE relocation error by adding `wrt ..plt` — add `-no-pie` to the link instead.
- It is PIE that breaks the simple syntax, not dynamic linking. `clang -static` also works, because it implies non-PIE; it was the original choice here, dropped in favour of `-no-pie` because the flag names the actual constraint. See `docs/adr/0001-link-non-pie.md`.
- Standard output is a pipe under `docker exec` without `-t`, so nothing that buffers it flushes on its own. `main` calls `setvbuf` for line buffering before it prints anything. Do not remove that call: without it an interactive session shows nothing at all until Ctrl-D, and then prints the whole session at once. See `docs/system/build-and-tests.md`.
- The `cat` in the container is the Rust uutils one, not GNU. It holds what it reads from the terminal when its output is a pipe, so `cat lib/prelude.f - | ./build/mforth` answers a typed line only when the next line is typed. Neither `-u` nor `stdbuf` reaches it, because it is not libc stdio. `make run` feeds the terminal half through `sed -u ''` instead. `make test` is unaffected: it compares the output after mforth has ended.
- A file written on the host is not reliably there for the next `docker exec`. The host is macOS and the repository reaches the container over a mount, so a file created and then read by the command that follows can arrive empty or half-written. Nothing fails: `cat` writes to stderr inside a pipeline that still exits 0, and the run gives a short answer instead of an error. Feed generated input down the container's stdin instead — `docker exec -i -w /Workspace/mforth nasm-docker-amd64 build/mforth` with the text piped in — and write a file only when a later command will read it.
- Plain gdb does not work in `nasm-docker-amd64`. The container runs x86-64 code through Rosetta, and `gdb build/mforth` fails with "Couldn't get registers: Input/output error". Start the program with `ROSETTA_DEBUGSERVER_PORT=1234` set, then connect gdb with `target remote :1234`. Run the `docker exec` with `--privileged`, because the container was created without `--cap-add=SYS_PTRACE`. Give gdb `set tdesc filename lab/tools/rosetta-registers.xml` before connecting, or the register window stays empty. `lab/debug` does all of this. gdb is not in the image: it was installed into the container by hand. A failed attempt can leave a `core` file of about 275 MB in the working directory.
- A headless Firefox screenshot of a lab page shows only the static header. `lab/lab.js` fetches the exercise list and each page's Markdown after the page has loaded, and `firefox --screenshot` captures before that. To check a page's text, run its Markdown through `lab/vendor/marked/marked.umd.js` in node, or open the page in a normal Firefox window.
