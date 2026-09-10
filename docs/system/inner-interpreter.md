# Inner interpreter

mforth is indirect threaded. A word is a code field followed by a body. The word's execution
token is the address of its code field, and the code field holds the address of machine code.
`NEXT`, a macro defined once in `include/mforth.inc`, loads the token IP points at, steps IP
past it, and jumps through the code field. Every word ends with `NEXT`. BYE is the exception:
it calls libc `exit` and never returns.

Case says what a name is. Uppercase is the Forth machine's own vocabulary — the inner
interpreter and its registers (`NEXT`, `IP`, `W`, `DSP`, `RSP`) — a Forth word written as a
programmer types it (`CR`, `EXIT`), or an assemble-time constant (`DATA_STACK_SIZE`,
`F_IMMEDIATE`). Lowercase is everything the assembler works in: labels (`main`, `docol`,
`xt_exit`, `code_exit`) and the macros that lay definitions down (`header`, `defcode`,
`defword`). It is not `%macro` against label that decides the case — `NEXT` and `defcode` are
both macros. `docol` has no uppercase form because it has no Forth name at all.

A word written in assembly puts its code field in `section .data` and its machine code in
`section .text`, next to each other in the source. Since ticket 003 a header comes before the
code field, and the `defcode` and `defword` macros in `include/dictionary.inc` lay down both
halves — see `docs/system/dictionary.md`. A word written in Forth points its code
field at `docol` in `src/inner.asm` and ends its body with the execution token of EXIT.
`docol` saves IP on the return stack and points IP at the body; EXIT puts IP back.

A word's `section` directives are inside the `defcode` and `defword` macros, so the source
shows the word's comment and then the macro call. A directive written out in the source opens
a region of plain storage — `.bss`, `.rodata`, the `latest` cell — and goes above the comment,
because it covers what follows rather than belonging to one definition.

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
a word that does use the machine stack must restore it before reaching NEXT. The subroutines
`find_name` and `refill` each push rbp on entry and pop it before they return, which both
saves the caller's rbp and keeps the alignment for the libc call they make.

Every subroutine called with `call` carries a register table in its comment: an `in` row for
each argument register and an `out` row for each result register. `find_name` in
`src/words.asm` has one, and so do `refill`, `parse_word` and `to_number` in `src/outer.asm`.
`docol` carries one as well, although a jump reaches it rather than a `call`, because NEXT
hands it the execution token in W.

Both stacks are 65536-byte `.bss` regions in `src/inner.asm`. They grow downward and their
pointer holds the address of the top item. Neither is checked for overflow or underflow.

`main` reads the first line, then points IP at `interpreter` in `src/outer.asm` and runs
`NEXT`. That is a thread of one cell holding the execution token of INTERPRET, and it is the
program mforth runs — see `docs/system/outer-interpreter.md`. Before ticket 004 `main` pointed
IP at a thread written out by hand in `src/mforth.asm`; that thread is gone.

`nasm -Wall` reports `reloc-abs-qword` and `reloc-rel-dword` on every cell holding a code
address, such as `dq docol` in `.data`. Those relocations are what a thread is made of in a
non-PIE binary. The Makefile does not pass `-Wall`.

`include/mforth.inc` declares `DEFAULT ABS`. A label in a non-PIE binary is an address the
linker knows, so `mov r14, [latest]` reads the cell at that address. nasm 3 warns
`implicit-abs-deprecated` on such a reference when no `DEFAULT` is declared, and that warning
shows in a plain `make`.
