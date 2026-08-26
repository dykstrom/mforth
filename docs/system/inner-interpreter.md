# Inner interpreter

mforth is indirect threaded. A word is a code field followed by a body. The word's execution
token is the address of its code field, and the code field holds the address of machine code.
`NEXT`, a macro defined once in `include/mforth.inc`, loads the token IP points at, steps IP
past it, and jumps through the code field. Every word ends with `NEXT`. BYE is the exception:
it calls libc `exit` and never returns.

Case says what a name is. Uppercase is a macro or `%define` (`NEXT`, `IP`, `DSP`) or a Forth
word written as a programmer types it (`CR`, `EXIT`); every assembly label is lowercase
(`main`, `docol`, `xt_exit`, `code_exit`). `docol` has no uppercase form because it has no
Forth name at all.

A word written in assembly puts its code field in `section .data` and its machine code in
`section .text`, next to each other in the source. A word written in Forth points its code
field at `docol` in `src/inner.asm` and ends its body with the execution token of EXIT.
`docol` saves IP on the return stack and points IP at the body; EXIT puts IP back.

In a word, the `section` directive sits under the word's comment and directly above the label,
so each word reads as one block starting at its name. A directive that opens a region of plain
storage instead — `.bss`, `.rodata` — goes above the comment, because it covers what follows
rather than belonging to one definition.

EXIT sits in `src/inner.asm` and not with the other words in `src/words.asm` because it is the
other half of `docol`: together they are how a word written in Forth is entered and left, and
they are the only code that touches the return stack. It has a code field and an execution
token only because it has to appear in a thread — a programmer does not type it, `;` compiles
it.

`include/mforth.inc` names the registers: IP is rbx, the data stack pointer DSP is r12, the
Forth return stack pointer RSP is r13, and W is rax. The first three are callee-saved, so a
word calls libc without saving them — see `docs/adr/0003-forth-machine-in-callee-saved-registers.md`.
W holds a value only from NEXT's jump until `docol` reads it; rax is scratch everywhere else.
`main` aligns the machine stack once with `sub rsp, 8`, and no word touches rsp afterwards, so
a word that does use the machine stack must restore it before reaching NEXT.

Both stacks are 65536-byte `.bss` regions in `src/inner.asm`. They grow downward and their
pointer holds the address of the top item. Neither is checked for overflow or underflow.

`nasm -Wall` reports `reloc-abs-qword` and `reloc-rel-dword` on every cell holding a code
address, such as `dq docol` in `.data`. Those relocations are what a thread is made of in a
non-PIE binary. The Makefile does not pass `-Wall`.
