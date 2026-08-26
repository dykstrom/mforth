# Build and tests

`make` assembles `src/mforth.asm` into `build/mforth.o` and links that into `build/mforth`.
`src/mforth.asm` is the only file nasm is invoked on. Every other `src/*.asm` and
`include/*.inc` file reaches it through `%include`, so there is one assemble step and one
link step, and internal labels need no `global` or `extern`. The Makefile's `SOURCES`
wildcard lists those files as prerequisites, so editing any of them rebuilds. `build/` is
ignored by git.

mforth's entry point is `main`, not `_start`. libc's startup code runs first and calls it,
which is what makes `puts` and the rest of libc available.

`make test` runs `tests/run.sh` from the repository root. Each `tests/<name>.expected` holds
the output mforth must produce. When `tests/<name>.f` exists it is fed to mforth on standard
input; otherwise mforth reads `/dev/null`. The runner prints one line per test, shows a
`diff -u` for each failure, and exits non-zero if any test failed.

Expectation files end in `.expected`, not `.out`. `.gitignore` ignores `*.out` as a build
artifact, so a test named `<name>.out` would be left out of the repository without warning.

`.` prints a space after the number, so a line in `tests/*.expected` that ends in a printed
number ends with a space. `tests/run.sh` compares with `diff -u`, which counts that space. An
editor that strips trailing whitespace on save turns a passing test into a failing one, and
the diff it prints looks identical on both sides.
