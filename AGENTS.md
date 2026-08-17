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
| `docs/` | Durable project context. Sub-folder layout below shows where each kind of doc goes. |

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
| Assemble | `nasm -f elf64 <file>.asm -o <file>.o` |
| Link | `clang -no-pie <file>.o -o <name>` |

The container is not auto-started (restart policy `no`). If `docker exec` fails because Colima or `nasm-docker-amd64` is not running, ask the developer before starting either. Do not run `colima start` or `docker start` unprompted.

## Gotchas

- `-no-pie` is load-bearing for readability, not just packaging. In a non-PIE executable the linker synthesizes a PLT stub for `puts`, so `call puts` assembles and links as written, and a string's address is just `mov rdi, msg`. Under clang's default PIE both break: the call fails with `relocation R_X86_64_PC32 ... can not be used when making a PIE object` and must be written `call puts wrt ..plt`, and the address must become `lea rdi, [rel msg]`. Never "fix" a PIE relocation error by adding `wrt ..plt` — add `-no-pie` to the link instead.
- It is PIE that breaks the simple syntax, not dynamic linking. `clang -static` also works, because it implies non-PIE; it was the original choice here, dropped in favour of `-no-pie` because the flag names the actual constraint. See `docs/adr/0001-link-non-pie.md`.
