# Build and tests

`make` assembles `src/mforth.asm` into `build/mforth.o` and links that into `build/mforth`.
`src/mforth.asm` is the only file nasm is invoked on. Every other `src/*.asm` and
`include/*.inc` file reaches it through `%include`, so there is one assemble step and one
link step, and internal labels need no `global` or `extern`. The Makefile's `SOURCES`
wildcard lists those files as prerequisites, so editing any of them rebuilds. `build/` is
ignored by git.

mforth's entry point is `main`, not `_start`. libc's startup code runs first and calls it,
which is what makes `puts` and the rest of libc available.

`main` calls `setvbuf` on `stdout` before it prints anything, asking for line buffering.
Do not remove it. libc otherwise chooses the buffering from what the output is: a terminal
is flushed at every newline, but a pipe is held until 4096 characters have gathered or the
process ends. Standard output is a pipe whenever mforth is run through `docker exec` without
`-t`, which is how `make run` is usually reached, and an interpreter that answers only after
Ctrl-D is no use to anyone. The call makes the behaviour the same either way.

`make test` runs `tests/run.sh` from the repository root. Each `tests/<name>.expected` holds
the output mforth must produce. The runner feeds `lib/prelude.f` first and then
`tests/<name>.f` when that file exists, with `cat lib/prelude.f "$input" | "$mforth"`, so a
test may use the words the prelude defines. A test with no `.f` file gets `/dev/null` as the
second half. The runner prints one line per test, shows a `diff -u` for each failure, and
exits non-zero if any test failed.

`make run` pipes the same file in ahead of the terminal:
`{ cat lib/prelude.f; sed -u ''; } | ./build/mforth`. mforth has no word that loads a file, so
both commands hand the work to the shell. The terminal half goes through `sed -u` because the
`cat` on Ubuntu 26.04 is the Rust uutils one, which holds terminal input in a buffer when its
output is a pipe. See `docs/system/prelude.md`.

INTERPRET answers every line it reads with ` ok`, the prelude's comment lines included, so
every `tests/*.expected` file begins with the banner and then one ` ok` line per line of
`lib/prelude.f`. Adding a line to the prelude changes the output of all six tests.

Expectation files end in `.expected`, not `.out`. `.gitignore` ignores `*.out` as a build
artifact, so a test named `<name>.out` would be left out of the repository without warning.

`.` prints a space after the number, so a line in `tests/*.expected` that ends in a printed
number ends with a space. `tests/run.sh` compares with `diff -u`, which counts that space. An
editor that strips trailing whitespace on save turns a passing test into a failing one, and
the diff it prints looks identical on both sides.

The first line of every `tests/*.expected` file is the banner mforth prints at startup, so the
version string lives in `src/mforth.asm` and again in each expected file. Raising the version
means editing all of them, and each new test adds another place to edit. A missed one fails
with a diff on the banner line and nothing else.
