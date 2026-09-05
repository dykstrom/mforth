# 0005. The interpreter loop is one cell of thread

*2026-09-04*

## Context

The outer interpreter has to run forever: read a word, run it or push it, then read the
next one. In a Forth that loop is a word called QUIT, written in Forth as INTERPRET
followed by a branch back to the start. mforth cannot write it that way in this iteration.
BRANCH and 0BRANCH read an offset stored inline in a thread and move IP, and they arrive
with ticket 007, while ticket 004 is where a person first types at mforth. Two other shapes
were available. The loop could be an ordinary assembly loop, but running a word the
dictionary gave back still needs the Forth machine: a code field is reached by `jmp [W]`,
and the word ends with NEXT, which runs whatever IP points at. Such a loop therefore has to
hand the machine a thread anyway, a mutable one of two cells holding the token to run and
then the token of the interpreter. The other option was to define BRANCH here and write
QUIT in Forth, which takes work from ticket 007 and puts a branch word on screen before the
part of the talk that is about control flow.

## Decision

We will make the loop a thread of one cell. `src/outer.asm` holds
`interpreter: dq xt_interpret`, and INTERPRET begins with `mov IP, interpreter`, which puts
IP back on the cell NEXT has just stepped past. `main` points IP at that cell to start the
machine.

## Consequences

Every word INTERPRET runs comes back to INTERPRET through that word's own NEXT, and nothing
in the word knows it was reached from the interpreter rather than from a thread. A word
written in Forth comes back the same way, because `docol` saves IP and EXIT puts it back, so
the interpreter needs no case for the two kinds of word. The loop is data: one cell and one
instruction, with no mutable state to explain. mforth has no QUIT word, which a reader who
knows Forth will look for, and the comment on INTERPRET is where that is said. INTERPRET is
entered by a jump and not a call, so no path out of it may use `ret` — each one ends in NEXT
or in `jmp [W]`. Ticket 006 hangs the compiling half of the interpreter off the same cell.
When BRANCH lands in ticket 007 the loop could become a Forth-level QUIT; that would be a
new decision superseding this one, not an edit to it.
