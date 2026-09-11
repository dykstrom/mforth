# 0011. Work lives in an assembly subroutine and the Forth word wraps it

*2026-09-11*

## Context

The outer interpreter does by hand what several Forth words also do. INTERPRET looks a name up
for every word a person types, appends a cell for every word it compiles, reads a line when the
last one is spent, and asks whether text spells a number. Those are FIND, ",", and the work
behind KEY and NUMBER. Reaching them as Forth words would mean pushing arguments onto the data
stack and entering the inner interpreter to arrive at machine code the interpreter is already
standing in. The alternatives were to write each piece of work as a Forth primitive only, and
have INTERPRET push arguments and jump through its code field to reach it; or to write the work
twice, once inside the primitive and once inside the interpreter.

## Decision

We will write each piece of work as an ordinary assembly subroutine that takes its arguments in
the registers the System V ABI uses for a C call, and make the Forth word a wrapper that moves
cells between the data stack and those registers. `find_name`, `header_flags`, `comma_cell`,
`create_header`, `refill`, `parse_word`, `to_number` and `print_text` are those subroutines;
FIND, "," and CREATE are wrappers over three of them, and INTERPRET calls the subroutines
directly.

## Consequences

A subroutine can be explained on its own: it carries a register table in its comment saying
what it takes and what it leaves, and it is called the way libc is called, so a reader who
knows the ABI knows the convention already. The same work serves the interpreter and the
programmer without being written twice. The costs are that a reader meets two names for one
piece of work, FIND and `find_name`, and that every such subroutine must respect what the Forth
machine keeps in registers: IP, DSP and RSP are callee-saved, which `docs/adr/0003` chose, and
a subroutine that pushes has to leave the machine stack 16-byte aligned for the call it makes.
`print_text` ends in `jmp printf` rather than a call for that reason.
