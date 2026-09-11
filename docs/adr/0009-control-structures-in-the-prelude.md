# 0009. Control structures that can be written in Forth live in the prelude

*2026-09-11*

## Context

Ticket 007 wrote IF, ELSE and THEN in assembly, beside the BRANCH and 0BRANCH they compile.
Ticket 008 added `lib/prelude.f` and the claim that most of a Forth is written in Forth, and
those three words are the strongest evidence available for it: each is one line, and each does
nothing but append cells and store into one appended earlier. Two things stopped a person
writing them. A definition that compiles another word has to name that word's execution token,
which is an address nobody can type, and only the third argument of `defcode` could mark a
definition immediate. The alternatives were to leave all nine compiling words in assembly,
where the talk already explains them; to move all nine, leaving `src/control.asm` holding the
run time alone; and to reach the token through the standard's fuller spelling of `'` with `[`,
`]` and LITERAL, which is three more words to explain and needs a state the interpreter does
not have.

## Decision

We will define a control structure in `lib/prelude.f` when Forth can express it, and keep in
assembly only what assembly is needed for. IF, ELSE and THEN move to the prelude, and `[']`
and IMMEDIATE are added to assembly so that they can. BEGIN, UNTIL, WHILE, REPEAT, DO and LOOP
stay in `src/control.asm` although the same two words would let them go, so that the source
holds one worked example of each kind side by side.

## Consequences

A person watching can now write a compiling word, because `[']` and IMMEDIATE are the whole
toolkit and both are ordinary words. `tests/control-flow.f` was written against the assembly
IF and passes unchanged against the Forth one, which is the evidence that nothing was lost.
Later words follow the same rule: ticket 009's `."` belongs in the prelude unless it needs
something Forth cannot reach. The costs are that control flow is now described in two files
rather than one, that the prelude is read before every test so each `tests/*.expected` file
carries one ` ok` line per prelude line, and that `[']` compiles LIT 0 for a name no word has
and says nothing about it. `docs/adr/0008` describes nine immediate words in
`src/control.asm`; six are there now, and that ADR stands as it was written.
