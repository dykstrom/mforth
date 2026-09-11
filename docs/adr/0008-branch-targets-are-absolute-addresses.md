# 0008. Branch targets are absolute addresses

*2026-09-10*

## Context

A branch in threaded code keeps its destination in the cell after the branch word's own token.
Forth implementations usually put a relative offset there: jonesforth's BRANCH is
`add IP, [IP]`, and a word that patches one computes the distance from the hole to the
destination. An absolute address is the other option, and IP is then loaded rather than
adjusted. mforth compiles into one fixed region, `dictionary_space`, and has no word that
copies, saves or relocates a definition. Ticket 007's scope text said "offset", so choosing
the address deviates from the plan as written as well as from the usual implementation.

## Decision

We will store an absolute address. `BRANCH` is `mov IP, [IP]`, `0BRANCH` loads the same cell
when its flag is 0, and a word that resolves a branch stores `HERE` into the hole with no
arithmetic.

## Consequences

The nine immediate words in `src/control.asm` contain nothing but `comma_cell` calls and
stores, which is what lets the talk say a control structure is two words passing an address to
each other. `THEN` is three instructions and has no distance to work out, so a reader
following `IF` to `THEN` sees one address written and later read, rather than a subtraction
whose operands both need explaining. The costs are that a compiled definition cannot be moved
in memory — a later word that saved or reloaded the dictionary would have to rewrite every
branch cell, or change to offsets — and that a reader who knows another Forth expects
`add IP, [IP]`, which the comment on `BRANCH` names alongside jonesforth. Nothing in mforth
moves a definition.
