# 0002. Keep the container out of the Makefile

*2026-08-17*

## Context

mforth targets Linux/x86_64. The machine it is developed on runs macOS on arm64 and cannot
assemble or run it, so the build happens inside a container. Three ways to connect the two
were considered. Put the container invocation in the Makefile behind a `uname` test, so bare
`make` re-invokes itself in the container when the host is not Linux/x86_64 — convenient, at
the cost of a conditional in the Makefile that has nothing to do with building the program.
Add a wrapper script that supplies the `docker exec` prefix — short to type, one more file to
explain. Or leave the Makefile alone and let the caller supply the prefix, which `AGENTS.md`
already documents.

## Decision

We will keep the Makefile to nasm and clang. The caller supplies the container prefix:
`docker exec -w /Workspace/mforth nasm-docker-amd64 make`.

## Consequences

The Makefile reads as a plain NASM Makefile and works unchanged on any Linux/x86_64 machine.
A reader learns what the toolchain does and nothing about our containers. The cost falls on
whoever builds from the macOS host, who types the prefix every time or works from an
interactive shell inside the container. The container's name and mount point stay in
`AGENTS.md` and `README.md`, so renaming the container leaves the build untouched.
