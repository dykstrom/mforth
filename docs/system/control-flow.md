# Control flow

`src/control.asm`: eleven words. `BRANCH` and `0BRANCH` move IP; `(DO)`, `(LOOP)` and `I`
run inside a counted loop; and the six immediate words compile the other three into a
definition. Before control flow arrived IP only went forward — a cell at a time in NEXT, one
more in LIT — so a body ran from its first cell to its `xt_exit` and nothing could jump.

Forth's control structures are not syntax. `THEN`, `LOOP` and the rest are ordinary words
marked `F_IMMEDIATE`, so they run while the compiler is compiling, and each one does nothing
but append a cell with `comma_cell` or store into a cell appended earlier. INTERPRET needs no
case for any of them.

`IF`, `ELSE` and `THEN` are not in this file. They are three lines of Forth in
`lib/prelude.f`, and they do exactly what the words here do — see `docs/system/prelude.md`.
`BRANCH` and `0BRANCH` cannot move, because moving IP is what only assembly can do. The loops
could and did not: `docs/adr/0009-control-structures-in-the-prelude.md` records why.

## The two branch words

| Word | Stack effect | What it does |
|------|--------------|--------------|
| `BRANCH` | `( -- )` | `mov IP, [IP]` — jumps to the address in the cell after it |
| `0BRANCH` | `( flag -- )` | Jumps the same way when flag is 0; steps over the cell when it is not |

The cell holds an **absolute address**, not an offset. The jump is then one instruction and a
patch is one store with no arithmetic: `THEN` writes HERE into the cell and is done.
jonesforth stores a relative offset, which would let a compiled definition be moved in memory.
mforth never moves one. See `docs/adr/0008-branch-targets-are-absolute-addresses.md`.

`0BRANCH` is the only conditional in the system. `UNTIL` and `WHILE` compile it here, and `IF`
compiles it from the prelude. Jumping on false rather than true is what makes `IF` read
forwards: `IF` compiles a jump *over* the code it guards, so a false flag skips it.

## Holes and targets

Two kinds of address travel on the data stack between an opening word and its closing word:

- A **hole** — the address of a placeholder cell that a later word overwrites with HERE. `WHILE` leaves one, and so do `IF` and `ELSE` in the prelude.
- A **target** — an address already known, compiled as something to jump back to. `BEGIN` and `DO` leave one.

The first three rows below are the prelude's; the rest are this file's. The kinds of address
are the same either way, which is why the words can live in either place.

| Word | Compiles | Data stack |
|------|----------|-----------|
| `IF` | `xt_zero_branch`, then 0 as a placeholder | leaves the hole |
| `ELSE` | `xt_branch`, then 0 as a placeholder | takes `IF`'s hole, fills it, leaves its own |
| `THEN` | nothing | takes the hole, fills it with HERE |
| `BEGIN` | nothing | leaves HERE as the target |
| `UNTIL` | `xt_zero_branch`, then the target | takes the target |
| `WHILE` | `xt_zero_branch`, then 0 as a placeholder | leaves the hole above `BEGIN`'s target |
| `REPEAT` | `xt_branch`, then `BEGIN`'s target | takes the hole and the target; fills the hole with HERE |
| `DO` | `xt_do_runtime` | leaves HERE as the target |
| `LOOP` | `xt_loop_runtime`, then the target | takes the target |

`ELSE` does two jobs: it compiles the jump that carries the true part over the false part, and
it fills `IF`'s hole with the address after its own placeholder, so `IF`'s jump lands at the
start of the false part. In Forth that reads `SWAP HERE SWAP !`, and the address after the
placeholder is just HERE once the placeholder has been appended.

`REPEAT` compiles the jump back to `BEGIN` *before* it fills `WHILE`'s hole, so leaving the
loop lands after that jump. It holds both addresses in r8 and r9 across its two `comma_cell`
calls, because `comma_cell` touches only rax and rdi.

Nothing checks that a structure is balanced, or which kind of address it was handed. A stray
`THEN` stores a cell at whatever address was on the data stack, and `IF ... UNTIL` compiles
without complaint. That is the answer the two stacks, the dictionary region and `@` all
already give.

## The counted loop

`DO` and `LOOP` are immediate and compile the two words that run:

| Word | Stack effect | What it does |
|------|--------------|--------------|
| `(DO)` | `( limit start -- )` `( R: -- limit index )` | Moves both to the return stack, index on top |
| `(LOOP)` | `( -- )` | Adds one to the index; jumps to the inline target unless the index equals the limit, in which case it drops both and steps over the target |
| `I` | `( -- n )` | The top of the return stack, which is the index |

The parentheses are Forth's own way of naming the run-time half of a compiling word. Both are
findable words like any other.

`(LOOP)` stops when the index **equals** the limit, which is what Forth 2012 says. `10 0 DO I
. LOOP` prints 0 to 9. A loop whose limit is not above its start does not run zero times:
`0 0 DO LOOP` counts all the way round through every 64-bit value before the index meets 0
again. The standard has `?DO` for that case and mforth does not.

## The return stack is shared

The limit and index live on the return stack, as they do in every Forth. That stack also holds
the address `docol` saved and anything `>R` parked there. Three things follow, and nothing
reports any of them:

- `I` inside a word *called from* a loop body reads that word's `docol`-saved IP, not the index, because the call put a cell on top of the index.
- `EXIT` inside an unfinished loop returns to a loop parameter instead of the caller.
- `R@` and `R>` in a loop body reach the index, not whatever the return stack held before the loop started.

`>R` followed by `R@` still works: the parked cell goes on top of the index. What breaks is a
`>R` still unbalanced when `(LOOP)` runs, because `(LOOP)` then reads the parked cell as the
index. This is why a Forth programmer keeps `>R` and `R>` in the same breath.

The three are observable. `: PEEK 3 0 DO R@ . LOOP ;` prints `0 1 2`, the indices, while
`: PEEK2 R@ . ;` outside a loop prints the address `docol` saved. And `: SHOW I . ;` called
from a loop body prints that address three times rather than `0 1 2`.

A nested `DO` loop works and the inner `I` is correct, because `(DO)` pushed the inner pair on
top. The outer index is unreachable: `J` is the word that would reach it and mforth does not
have it.

## Testing

`tests/control-flow.f` holds one structure per case, diffed against
`tests/control-flow.expected`.

| Word | Body | Prints | Covers |
|------|------|--------|--------|
| `ONE-OR-ZERO` | `IF 1 ELSE 0 THEN` | `1 0` | `IF`/`ELSE`/`THEN`, both paths |
| `PRINT-IF` | `IF 42 . THEN` | `42` | `IF`/`THEN`, taken and not taken |
| `ABS-WITH-IF` | `DUP 0 < IF 0 SWAP - THEN` | `5 5` | A conditional doing real work |
| `NESTED-IF` | `IF IF 2 ELSE 1 THEN ELSE 0 THEN` | `2` | `IF` inside `IF` |
| `COUNT-TO-5` | `0 BEGIN 1 + DUP 5 = UNTIL` | `5` | `BEGIN`/`UNTIL` |
| `COUNT-DOWN` | `BEGIN DUP 0 > WHILE DUP . 1 - REPEAT DROP` | `3 2 1` | `BEGIN`/`WHILE`/`REPEAT` |
| `PRINT-0-TO-9` | `10 0 DO I . LOOP` | `0` to `9` | `DO`/`LOOP` and `I` |
| `NESTED-LOOP` | `3 0 DO 2 0 DO I . LOOP LOOP` | `0 1 0 1 0 1` | Nested `DO`/`LOOP` |
| `SUM-0-TO-4` | `0 5 0 DO I + LOOP` | `10` | A loop accumulating on the data stack |

Trailing spaces are significant: `.` prints a space after the number and ` ok` begins with
one.

## What is not here

`LEAVE` and `+LOOP`. `J`. `?DO`. Recursion words. Any check on structure balance.

The interpreter's own loop is still one cell of thread, not a Forth-level `QUIT`. The branch
words that would make `QUIT` possible now exist, but
`docs/adr/0005-interpreter-loop-in-one-cell-of-thread.md` stands until a decision supersedes
it.
