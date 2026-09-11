# 0012. Nothing is checked at run time

*2026-09-11*

## Context

Every region mforth uses has an end, and every one can be run past: two stacks of 8192 cells, a
65536-byte dictionary region, and a 256-byte input buffer. A division by zero raises SIGFPE and
kills the process, a control structure need not be balanced, an address handed to `@` need not
be one mforth may touch, and a definition abandoned by an unknown word stays in the dictionary.
A check at each of those places is an instruction or two and a message to print. The source is
read aloud to an audience, and `docs/architecture/design-goals.md` makes readability binding and
forbids trading it away. The alternatives were to check and report at every site, which adds
code to read past in the words a reader is meeting for the first time; or to check at a few
sites only, which invites the question why this one and not that one.

## Decision

We will check nothing at run time, and say so in the comment wherever the omission shows.

## Consequences

Every word stays the size a reader can hold: DROP is one instruction, and the comparison words
are five. Nothing in the source needs an error path, a message table, or a way to report a
failure back to a person. The costs are borne by the person typing: a `7 0 /` ends the session,
a deep enough loop writes past a stack, a line longer than 256 characters loses its tail, and a
failed definition leaves a hidden word behind. Later work may not add a check to one word
without superseding this, because a single word that checks its arguments makes the absence
everywhere else look like an oversight rather than a rule.
