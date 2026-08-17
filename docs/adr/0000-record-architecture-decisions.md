# 0000. Record architecture decisions

*2026-08-17*

## Context

mforth exists to be explained to an audience, and the question an audience asks is "why is
it like this?". Without a record, the answer lives in commit messages, code comments, or
the developer's memory. Commit messages are ordered by time rather than topic and say what
changed, not what was rejected. Comments explain the line they sit on, not the choice
between alternatives. The `docs/` folder already separates what the code does from what it
must do, but neither place holds the reasoning.

## Decision

We will record each architecturally significant decision as a numbered ADR in `docs/adr/`,
in Nygard's slimmed form: Context, Decision, Consequences. An ADR is immutable once
shipped; we change course by writing a new ADR that supersedes the old one.
`docs/adr/README.md` holds the mechanics — numbering, naming, the supersession rule, and
the bar a decision must clear.

## Consequences

A reader can answer "why is it like this?" from the repository. The bar stays high: a
choice localized to one word or module goes to `docs/system/`, and a rule goes to
`docs/architecture/`, so `adr/` stays short enough to read end to end. Recording a decision
costs a file at the time it is made, when the alternatives are still fresh — writing one
afterwards is the failure mode this decision accepts as a risk.
