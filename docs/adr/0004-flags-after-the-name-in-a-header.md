# 0004. Flags after the name in a word's header

*2026-08-26*

## Context

Every word in mforth carries its own name, and a name is as long as it is. A header therefore
has no fixed size, and where the flags sit decides who can read them. Ticket 006 needs them:
the compiler has to ask whether the word it just looked up is immediate, at a point where all
it holds is an execution token. Two shapes were available. jonesforth packs the flags into the
length byte in front of the name, which is the shape most Forth literature shows. The Forth
2012 standard sidesteps the question by having FIND return the execution token together with a
flag saying whether the word is immediate. Both put the flags in front of a variable-length
name, and from an execution token the length byte is then an unknown number of bytes back.

## Decision

We will give the flags a cell of their own, after the name and immediately before the code
field. FIND leaves the execution token alone, or 0, and a word's flags are read at `[xt - 8]`.

## Consequences

Both directions through a header are fixed steps: the name is always at header + 8 for code
that walks the chain, and the flags are always one cell behind the code field for code that
holds a token. FIND keeps a stack effect of two in, one out, and mforth needs no `>CFA`. The
costs are that FIND deviates from the standard, which the comment on FIND and
`docs/system/dictionary.md` both note; that a header is one cell larger than the packed byte
would make it, which design-goals permits because code size is a non-goal; and that the
rounding of the name up to a cell boundary now appears twice, in the header macro and again in
FIND, because both have to step over the padding to reach the flags. Ticket 006's CREATE will
be the third.
