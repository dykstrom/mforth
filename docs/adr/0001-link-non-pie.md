# 0001. Link non-PIE rather than static

*2026-08-17*

## Context

mforth calls libc from assembly and takes the addresses of its own data — `call puts` and
`mov rdi, msg`. Both lines are non-PIC. clang defaults to PIE on Linux/x86_64, and linking
a NASM object that contains them into a PIE fails: `relocation R_X86_64_PC32 against symbol
'puts@@GLIBC_2.2.5' can not be used when making a PIE object`. There were three ways out.
Keep PIE and write the assembly PIC-correct, as `call puts wrt ..plt` and
`lea rdi, [rel msg]`. Link `-static`, which implies non-PIE. Link `-no-pie` and keep a
dynamic libc. The first attaches a relocation-model explanation to every libc call and
every string reference, which the readability goal in
`docs/architecture/design-goals.md` rules out. The project documented `-static` before this
decision, on the mistaken grounds that dynamic linking was what broke the simple syntax.

## Decision

We will link with `clang -no-pie` against a dynamic libc. Non-PIE is what makes `call puts`
and `mov rdi, msg` legal, and `-no-pie` says exactly that at the link line, where a reader
looking for the reason will find it. `-static` produced the same result as a side effect of
a choice about packaging.

## Consequences

Every libc call and data reference stays in its plain form, and no source line carries a
relocation-model caveat. A future PIE relocation error must be fixed by putting `-no-pie`
back on the link line, never by adding `wrt ..plt` to the offending call. The binary now
needs a matching glibc where it runs, and is no longer a single file that can be copied to
an unprepared machine; the build environment is also where it runs, so this costs nothing
today. The assembly is non-PIC by construction, so making mforth PIE later means revisiting
every libc call and every data reference, not changing a flag.
