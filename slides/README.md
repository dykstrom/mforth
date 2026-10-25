# slides/

Two decks: one on x86-64 assembly, one on Forth. The assembly deck opens the
lab morning: enough assembly to start the lab in `lab/`, then what the lab is
and how to get a machine for it. The Forth deck is from the earlier talk,
which walked the repository commit by commit, and is no longer part of the
morning.

## Opening a deck

Open the file. reveal.js is vendored here, so nothing is fetched from the
network and no server is needed:

```sh
open slides/index.html
```

A local server is the other way, and the one to use if a browser ever
complains about a `file://` path:

```sh
cd slides && python3 -m http.server
```

Then go to `http://localhost:8000/`.

## Keys

| Key | What it does |
|-----|--------------|
| Arrow keys, space | Move between slides |
| `S` | Open the speaker view: notes, the next slide, and a timer |
| `F` | Full screen |
| `Esc` | Show every slide at once |
| `B` | Black the screen |

The speaker view opens in a second window. Put that window on your laptop and
the deck on the projector.

## Layout

| Path | What is there |
|------|---------------|
| `index.html` | Links the decks |
| `forth/index.html` | The Forth deck |
| `asm/index.html` | The x86-64 assembly deck |
| `theme/mforth.css` | The style both decks load. The only place the accent colours live |
| `theme/forth-highlight.js` | A highlight.js grammar for Forth, which highlight.js does not ship |
| `theme/x86-grammar.js` | Two corrections to highlight.js's x86 grammar: a label after a blank line, and the missing `%macro` |
| `examples/` | The assembly sources the x86-64 deck quotes, with a Makefile that builds and runs them. See `examples/README.md` |
| `vendor/reveal/` | reveal.js, committed. See `vendor/README.md` |

## Writing a deck

Copy `forth/index.html` or `asm/index.html` and take the slides out. The
class on `<body>` picks the accent: `deck-forth` is green, `deck-asm` amber.
Both are defined in `theme/mforth.css`, and a deck sets no colour of its own.

Mark a code block with the language: `class="language-x86asm"` for NASM,
`class="language-forth"` for Forth, `class="language-armasm"` for arm64. Add
`data-line-numbers="1|2-3"` to reveal the block a step at a time, one group of
lines per press.

Mark the one word on a line the eye should find first with
`<span class="mark">`. The assembly deck uses it for the register that differs
between two rows.

Put two things side by side with `<div class="compare">` holding two `<div>`s,
each starting with a `<p class="label">`. The assembly deck uses it for one
source file against another. A code line inside one of those columns has room
for about 48 characters, so strip the comments off a block that goes in and
put what they said in the speaker notes.

A code line runs off the right edge past 56 characters, and nothing warns you.
Put `class="wide"` on the `<pre>` when a line is longer. Keep a wide block
under 85 characters, which covers anything copied out of `src/` or
`lib/prelude.f`. Count the characters rather than trusting the browser window
you are looking at.

Put what you plan to say in `<aside class="notes">` inside the slide.

Some lab pages point at slides in the assembly deck, by title or by what a
slide shows. `lab/exercises/e3-plus/README.md` names the slide "Forth's +",
and the tier notes in `lab/tiers/` say what the talk did not cover. Before
you cut or rename a slide, search `lab/` for its title and its subject.

Nothing in `slides/` is built by the top-level `Makefile`: `make` and
`make test` do not look here. `examples/` has a Makefile of its own, run
by hand when an example changes.
