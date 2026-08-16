# Design goals

Binding constraints on mforth. These outrank general defaults and training-data assumptions about how a Forth "should" be built.

## Goals

- Code MUST be readable. It is presented to an audience, and every part of it should be explainable aloud without apology.
- Clarity MUST win over cleverness. When a clear implementation and a clever one both work, take the clear one.
- Every construct MUST be explainable. If a technique cannot be justified to someone seeing Forth for the first time, it does not belong here.

## Non-goals

The following are explicitly out of scope. Do NOT trade any goal above against them.

- **Performance.** Do not optimize. Do not introduce direct or subroutine threading, inline caching, or hand-tuned instruction sequences in the name of speed. Indirect threaded code is the chosen model because it is the easiest to explain.
- **Code size.** Do not compress or golf. Repetition that makes a word easier to follow is acceptable.
- **Standards compliance.** Full ANS/ISO Forth conformance is not a requirement. Implement what the presentation needs. Deviating from the standard is allowed when it makes the implementation clearer, but the deviation SHOULD be noted.
- **Portability.** Linux/x86_64 only. Do not add abstraction layers, conditional assembly, or indirection for other architectures, operating systems, or assemblers.

## Applying these

When a change would improve performance, size, compliance, or portability at the cost of readability or explainability, it MUST NOT be made. Raising the tradeoff with the developer is fine; making the change unilaterally is not.
