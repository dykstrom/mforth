# 0006. Division rounds toward zero

*2026-09-05*

## Context

Forth 2012 has two divisions. FM/MOD rounds the quotient toward negative infinity and leaves a
remainder with the sign of the divisor; SM/REM rounds toward zero and leaves a remainder with
the sign of the dividend. The standard lets `/MOD`, `/` and `MOD` follow either, so a system
chooses rather than inherits. The two agree except when exactly one operand is negative:
`-7 2 /MOD` leaves 1 and -4 under the first, and -1 and -3 under the second. x86-64 `idiv`
rounds toward zero, so that answer costs two instructions, `cqo` and `idiv`, while the other
needs a test on the sign of the remainder and a correction to both answers after them. Those
extra instructions are not a performance question, which design-goals rules out, but four more
lines to explain to an audience meeting Forth for the first time. Forths that round toward
negative infinity exist, so the answer mforth gives is not the only one a reader may expect.

## Decision

We will let `idiv` decide. `/MOD` rounds the quotient toward zero and the remainder takes the
sign of the dividend, so `-7 2 /MOD` leaves -1 and -3.

## Consequences

`/MOD` is the divide instruction and the two stores that put its answers on the stack, with no
branch in it, and the comment above it can say that division is the machine's own instruction
and stop there. The cost is the answer a reader who knows another Forth will not expect; the
comment on `/MOD` and `docs/system/core-words.md` both say so. Ticket 008 defines `/` and
`MOD` in Forth on top of `/MOD`, so both inherit the rounding, and changing to the other
division later would change three words rather than one. Division by zero raises SIGFPE and
ends the process, because nothing stands between the word and `idiv`.
