# The prelude

## Where a word is defined

- A word MUST be defined in `lib/prelude.f` when Forth can express it.
- Assembly MUST hold only what Forth cannot reach. `BRANCH` and `0BRANCH` move
  IP, and nothing written in Forth can.
- `BEGIN`, `UNTIL`, `WHILE`, `REPEAT`, `DO` and `LOOP` MUST stay in
  `src/control.asm`, although `[']` and `IMMEDIATE` would let them move, so the
  source holds one worked example of each kind.
- Source: [ADR 0009](../adr/0009-control-structures-in-the-prelude.md).

## Writing one

- A definition in `lib/prelude.f` MUST use only words defined above it. The
  outer interpreter looks a name up as it reads it, so there is no forward
  reference. See [../system/outer-interpreter.md](../system/outer-interpreter.md).
- A word that runs while the compiler is compiling MUST be marked with
  `IMMEDIATE` on a line after `;`. `;` clears the whole flags cell, so the mark
  cannot be given to `:`. See [../system/compiler.md](../system/compiler.md).

## Changing it

- A change to `lib/prelude.f` MUST regenerate all five `tests/*.expected`
  files in the same change. INTERPRET answers every line it reads with ` ok`,
  comment lines included, and `tests/run.sh` feeds the prelude to every test,
  so one added line changes the output of all of them. See
  [../system/build-and-tests.md](../system/build-and-tests.md).
