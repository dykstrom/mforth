# 0010. Text a word prints lives in that word's own thread

*2026-09-11*

## Context

Ticket 009 added `."`, which prints text from inside a definition. The text has to be
somewhere, and mforth already answers that question once: a number written in a definition
is compiled as the token of `LIT` and the value in the cell after it, and `LIT` reads that
cell and steps IP over it. Text could follow the same shape, as a length byte and the
characters after the token of `(.")`, padded out to the cell the next token starts on. The
alternative was to keep the text out of the thread: `."` would copy it to `HERE` and compile
`LIT` with its address, `LIT` with its length, and `TYPE`, which is three tokens of thread
and no arithmetic on IP at all. A third alternative, a table of strings held apart from the
dictionary, was never in play — mforth has one region and no allocator.

## Decision

We will carry the text inside the definition, as a counted string in the thread after the
token of `(.")`. Any later word that has to carry data with it — `S"`, `ABORT"` — does the
same.

## Consequences

A definition is one piece: everything `GREET` needs to run is between its code field and its
`xt_exit`, and the audience sees the thread holding data as well as tokens, which is the
point the iteration makes. `(.")` costs the arithmetic that steps IP over the text,
`(length + 8) & -8`, and that arithmetic is now in two places, because `."` does the same sum
to move `HERE`. The body of a word is no longer a list of tokens alone, so anything that
walks a body has to know that `(.")` is followed by data — `LIT` already required that, and
mforth has nothing that walks a body. Two words printing the same text carry two copies; the
text cannot be shared, and nothing frees it. `."` stays in assembly under the rule in
`docs/architecture/prelude.md`, because moving IP is what Forth cannot reach.
