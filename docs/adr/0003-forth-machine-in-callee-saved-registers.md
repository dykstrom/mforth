# 0003. Keep the Forth machine in callee-saved registers

*2026-08-24*

## Context

mforth's words call libc directly: `.` calls `printf`, CR calls `putchar`, BYE calls `exit`.
Each of those calls sits in the middle of a word, between the instructions that use the
interpreter's own registers and the NEXT that ends it, so the instruction pointer and both
stack pointers have to survive the call. The System V ABI splits the registers in two: a
called function may destroy rax, rcx, rdx, rsi, rdi and r8 to r11, and must give back rbx,
rbp and r12 to r15. The register assignment most Forth implementations in this style use,
jonesforth's, puts the instruction pointer in rsi so that `lodsq` fetches a token and
advances in one instruction, the data stack on the machine's rsp so that push and pop are
single instructions, and the return stack in rbp. Two of those three are caller-saved, so
each word that calls libc would open and close with four instructions that save and restore
them, and the data stack would be the C stack rather than a region of its own.

## Decision

We will keep the instruction pointer in rbx, the data stack pointer in r12 and the return
stack pointer in r13, all callee-saved, named IP, DSP and RSP by `%define` in
`include/mforth.inc`. W is rax, and it is live only from the jump at the end of NEXT until
`docol` reads it. `main` aligns the machine stack once with `sub rsp, 8`, and no word touches
rsp afterwards.

## Consequences

A word that calls libc is the call and nothing else: `.` is six instructions with no register
ceremony, and every word added later inherits that. Because rsp is aligned once and never
moved, no word has to align it either. Three callee-saved registers are now reserved for the
interpreter, which leaves rbp, r14 and r15 plus the caller-saved registers for anything a
word needs locally — enough, because words are short. A word that does need the machine stack
must leave rsp as it found it, 16-byte aligned, before reaching NEXT, or the next libc call in
any word crashes. `RSP` is Forth's return stack pointer and `rsp` is the machine's; NASM's
`%define` is case-sensitive, so writing the lowercase one by mistake assembles cleanly and
corrupts the C stack. rax carries nothing across NEXT, so no word may expect a value left in
it by the word before.
