# mforth

A 64-bit indirect-threaded-code (ITC) Forth for Linux/x86_64, written in NASM assembly.

mforth is the worked example for a presentation on Forth. The code is written to be read
aloud and explained: clarity wins over cleverness, and performance, code size, standards
compliance and portability are explicit non-goals. See
[`docs/architecture/design-goals.md`](docs/architecture/design-goals.md) for the binding
constraints.

## Building

The host is macOS/arm64 and cannot build. Everything is assembled and linked inside the
Docker container `nasm-docker-amd64`, with the repository mounted at `/Workspace/mforth`:

```sh
docker exec -w /Workspace/mforth nasm-docker-amd64 sh -c 'nasm -f elf64 <file>.asm -o <file>.o'
docker exec -w /Workspace/mforth nasm-docker-amd64 sh -c 'clang -static <file>.o -o <name>'
```

Static linking is load-bearing for readability, not just packaging: with `clang -static`,
`call puts` assembles and links as written, instead of having to be spelled
`call puts wrt ..plt`.

## Documentation

Project documentation lives in [`docs/`](docs/), split by what each kind of doc is for —
what the code does today (`system/`), what it must do (`architecture/`), and how the
decisions were reached (`adr/`, `reference/`, `working-notes/`).

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
