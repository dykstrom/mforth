# 0014. The decks live in this repository, at the top level

*2026-09-12*

## Context

Both decks quote the code they explain - NEXT from `include/mforth.inc`, IF from
`lib/prelude.f` - and they quote it by copying, so a change to the source leaves the slide
saying something that is no longer true. Where the decks live decides how likely anyone is to
notice. This repository already has a place for writing that is not code, but `docs/` has a
taxonomy that `AGENTS.md` states: system, architecture, adr, reference, working-notes. A deck
is none of the five, and putting it in one of them would cost that taxonomy its meaning. The
alternative to keeping them here was a repository of their own, which leaves mforth holding
only the Forth.

## Decision

We will keep both decks in this repository, in a top-level `slides/` directory, outside
`docs/`.

## Consequences

A snippet and the file it came from are one `git grep` apart, which is what ticket 005's
check against `src/`, `include/` and `lib/prelude.f` rests on. Whoever clones the repository
after the talk gets the decks with it. The `docs/` tree is untouched, so a reader looking for
durable context still finds five folders and no sixth kind of thing. `AGENTS.md` gains one row
in its directory index so that `slides/` is not a surprise. The costs are that `make`,
`tests/run.sh` and the container ignore `slides/` completely, so a reader who wants only the
Forth carries 1.2 MB of deck machinery anyway, and that nothing enforces the agreement between
a slide and the file it quotes - ticket 005 does it by reading.
