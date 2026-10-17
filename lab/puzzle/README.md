# puzzle/

The source of tier D's puzzle. **If you are doing tier D, stop reading
here:** these files are the answers.

Each `phaseN.asm` defines `int phaseN(const char *input)`, which returns 1
if it accepts the input and 0 if not. `tools/build.sh` assembles it without
`-g` and links it with `exercises/dN-phaseN/`, so `./debug dN` has only the
machine code to show. The attendee's `phaseN.asm` in that directory holds
the input.

| Phase | What it wants | One answer |
|-------|---------------|------------|
| 1 | The string it hands `strcmp` | `Brackets mean memory` |
| 2 | Four numbers: 2, then each one three times the last, less 1 | `2 5 14 41` |
| 3 | Five characters whose low four bits index a table to spell `forth` | `gobij` |

Data labels are named `s1`, `f1`, `t1` and so on rather than for what they
hold, because the symbol table is in the binary and gdb shows it.
