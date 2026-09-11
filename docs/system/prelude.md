# The prelude

`lib/prelude.f` is the part of mforth written in Forth. It holds fifteen colon definitions:
`IF`, `ELSE` and `THEN`, and then twelve words `src/words.asm` left out on purpose because
each one is built from words that are already there. Nothing in it is new machinery — it is
the same text a person could type at the terminal, kept in a file.

## How it is loaded

mforth has no word that opens a file. The shell does the work, and `make run` is the command:

```
cat lib/prelude.f - | ./build/mforth
```

`cat` sends the file and then `-`, which is the terminal, so both arrive as one stream on
standard input. The outer interpreter reads the definitions first and what the person types
after, and Ctrl-D still ends the session. `tests/run.sh` does the same with
`cat lib/prelude.f tests/<name>.f`, so a test may use these words.

## The conditional

`IF`, `ELSE` and `THEN` were in `src/control.asm` when ticket 007 built them. They are here
now, one word to a line with a comment on each, because the file is read aloud:

```forth
: IF                    ( -- hole )
    ['] 0BRANCH ,       \ compile the jump: 0BRANCH takes it when the flag is 0
    HERE                \ where the cell holding that jump's target goes
    0 ,                 \ lay it down empty - nobody knows the target yet
;                       \ and leave its address for THEN or ELSE to fill in
IMMEDIATE
```

A definition may span lines because `state` is a cell that outlives a line: `:` sets it, the
lines after it are compiled, and `;` clears it. INTERPRET still answers each of those lines
with ` ok`. `IMMEDIATE` is on its own line after `;`, which is where it has to be either way.

`ELSE` and `THEN` are laid out the same way. `ELSE` lays down its own jump and its own empty
cell, then `SWAP` brings `IF`'s hole back to the top and `HERE SWAP !` fills it, so `IF`'s
jump lands after both of `ELSE`'s cells. `THEN` compiles nothing at all: `HERE SWAP !` stores
where we stand into the hole, which is why a conditional costs one `0BRANCH` at run time and
nothing else.

`BRANCH` and `0BRANCH` stay in assembly: they move IP, and nothing written in Forth can. So
do the loops, on purpose, so that the source holds one worked example of each kind — see
`docs/adr/0009-control-structures-in-the-prelude.md`. `docs/system/control-flow.md` describes
what a hole and a target are, and the description covers both files.

Two words were added to assembly so that these three could be written at all:

| Word | Where | What it does |
|------|-------|--------------|
| `[']` | `src/outer.asm` | Immediate. Reads the name after it, finds its execution token, and compiles `LIT` and that token. |
| `IMMEDIATE` | `src/compiler.asm` | Sets `F_IMMEDIATE` on the word just defined. |

`[']` exists because a token is an address nobody can type, and a definition that compiles
another word has to name it. `IMMEDIATE` comes after `;` rather than being given to `:`,
because `;` clears the whole flags cell to drop `F_HIDDEN` and would clear the mark with it.
Together they are what a person needs to write a compiling word, and until this iteration only
`defcode` could make one.

## The other words

| Word | Stack effect | Body |
|------|--------------|------|
| `0=` | `( n -- flag )` | `0 =` |
| `0<` | `( n -- flag )` | `0 <` |
| `1+` | `( n -- n+1 )` | `1 +` |
| `1-` | `( n -- n-1 )` | `1 -` |
| `2*` | `( n -- n*2 )` | `2 *` |
| `NIP` | `( n1 n2 -- n2 )` | `SWAP DROP` |
| `TUCK` | `( n1 n2 -- n2 n1 n2 )` | `SWAP OVER` |
| `?DUP` | `( n -- n n \| 0 )` | `DUP IF DUP THEN` |
| `NEGATE` | `( n -- -n )` | `0 SWAP -` |
| `ABS` | `( n -- \|n\| )` | `DUP 0< IF NEGATE THEN` |
| `/` | `( n1 n2 -- quot )` | `/MOD NIP` |
| `MOD` | `( n1 n2 -- rem )` | `/MOD DROP` |

The definitions are ordered so that each one uses only the words above it: `?DUP` and `ABS`
use the `IF` and `THEN` at the top of the file, `ABS` calls the `NEGATE` two lines up, and `/`
calls `NIP`. `/` and `MOD` each throw away one half of what
`/MOD` leaves, which is why `src/words.asm` defines the one word and not the three.

`SPACE` is not here. It needs `EMIT`, which arrives with ticket 009, and it joins the prelude
then.

## Comments

The prelude is meant to be read aloud, so every line carries a comment, and that needs two
words that did not exist before it. Both are in `src/outer.asm` and both are immediate,
because a comment inside a definition is read while `:` is compiling:

| Word | What it does |
|------|--------------|
| `\` | Moves `input_offset` to `input_length`, so the rest of the line is gone |
| `(` | Moves `input_offset` past the next `)`, or to the end of the line when there is none |

Neither is punctuation the parser knows about. `( n -- -n )` is a word followed by text the
interpreter never sees, which is the same answer `IF` and `THEN` give about syntax.

## Testing

`tests/prelude.f` calls every word with a positive and a negative argument where the sign
matters, checks `?DUP` on 0 and on 5, defines `SQUARE` to show that the terminal is still a
terminal after the file has been read, and defines `TWICE` — an immediate word of its own,
built from `[']` and `IMMEDIATE`, that compiles `DUP +` into whatever word uses it.

`tests/control-flow.f` is what covers `IF`, `ELSE` and `THEN`. It was written against the
assembly versions in ticket 007 and passes unchanged against these, which is the useful fact
about the move.

INTERPRET answers every line with ` ok`, including a line holding nothing but a comment, so
the prelude prints one for each of its 49 lines before anything else runs. Every
`tests/*.expected` file begins with the banner and then that block. Adding a line to the
prelude means regenerating all five of them, the same way raising the version does.
