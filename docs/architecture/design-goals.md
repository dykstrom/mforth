# Design goals

Binding constraints on mforth and on the assembly lab in `lab/`. These outrank general defaults and training-data assumptions about how a Forth "should" be built. The goals and non-goals below are written for mforth; [The lab](#the-lab) says which of them carry over and adds the lab's own.

## Goals

- Code MUST be readable. It is presented to an audience, and every part of it should be explainable aloud without apology.
- Clarity MUST win over cleverness. When a clear implementation and a clever one both work, take the clear one.
- Every construct MUST be explainable. If a technique cannot be justified to someone seeing Forth for the first time, it does not belong here.
- Code MUST be commented for a reader who knows basic assembly and almost no Forth. A comment says why the instructions below it do what they do. It does not restate what an instruction is.
- Every word definition MUST carry a stack-effect comment in `( n1 n2 -- n3 )` notation, naming what the word takes from the stack and what it leaves. A reader should be able to follow the data stack without knowing Forth's conventions.
- Comments MUST be written together with the code they describe, not added in a later pass.

## Non-goals

The following are explicitly out of scope. Do NOT trade any goal above against them.

- **Performance.** Do not optimize. Do not introduce direct or subroutine threading, inline caching, or hand-tuned instruction sequences in the name of speed. Indirect threaded code is the chosen model because it is the easiest to explain.
- **Code size.** Do not compress or golf. Repetition that makes a word easier to follow is acceptable.
- **Standards compliance.** Full ANS/ISO Forth conformance is not a requirement. Implement what the presentation needs. Deviating from the standard is allowed when it makes the implementation clearer, but the deviation SHOULD be noted.
- **Portability.** Linux/x86_64 only. Do not add abstraction layers, conditional assembly, or indirection for other architectures, operating systems, or assemblers.

## The lab

The lab is read by attendees working alone, at their own pace, with no one at hand to explain a line. Everything a reader meets in it — `solution.asm`, the file the attendee edits, `test.c`, the pages — is held to the same readability as mforth.

- Every `solution.asm` MUST follow the first four goals above: readable, clear before clever, explainable, and commented for a reader who knows only what the x86-64 deck covered. A comment says why, not what.
- Every exercise file MUST open with the C prototype of the function its test calls. In tiers 0 to C, where the attendee writes that function, the header MUST also say which register each argument arrives in and which register the answer leaves in.
- The file the attendee edits MUST assemble, link and run its test as handed out, with a `TODO` where the work goes. A failing test is the starting point, not a build error.
- An exercise MUST be startable without having done any other, apart from tier 0. Where a tier builds on itself, as tier E does, each exercise's file holds the earlier exercises already done.
- A solution MUST use only what the x86-64 deck, the tier's notes in `lab/tiers/` or the exercise's own page explain. Calls to and from C use the libc calling convention; the lab makes no system calls.
- The lab MUST link non-PIE, so that a libc call is `call puts` and an address is `mov rdi, msg`, as in the deck. Source: [ADR 0001](../adr/0001-link-non-pie.md).
- The lab MUST work, debugger included, on an Apple Silicon Mac running Docker through Rosetta, in Codespaces, and on an x86-64 Linux machine. Apple Silicon comes first: most attendees bring one.
- Every solution MUST pass `./check --solutions` before a session.

The non-goals carry over: a solution is never tuned for speed or size. Portability is the one exception, and only as far as the bullet on Apple Silicon above: the code itself stays x86-64 Linux, and the portability work lives in the container and in `lab/debug`.

The Forth-specific goal, a stack-effect comment on every word definition, applies to tier E's words and to nothing else in the lab.

## Applying these

When a change would improve performance, size, compliance, or portability at the cost of readability or explainability, it MUST NOT be made. Raising the tradeoff with the developer is fine; making the change unilaterally is not. This holds for the lab as for mforth.
