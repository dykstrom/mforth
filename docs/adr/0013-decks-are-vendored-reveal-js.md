# 0013. The intro decks are reveal.js, vendored into the repo

*2026-09-12*

## Context

The talk walks this repository commit by commit, and two intro decks run before it, one on
Forth and one on x86-64 assembly. Four forces decided how to build them. A slide that carries
a code block wants that block revealed a line at a time, because both decks walk a sequence:
the three instructions of NEXT, the words that move the data stack. A presenter wants notes
and a timer. A room may have no wifi. And this repository holds about two thousand lines of
assembly and, until now, no third-party code at all. The alternatives were PowerPoint, whose
files carry no useful diff and whose code blocks are set by hand; Markdown rendered to PDF by
Marp or Beamer, which needs a node or LaTeX toolchain the container does not have and which
reveals nothing between page breaks; and plain HTML with a little CSS, which would fit this
repository best but leaves the speaker notes and the timer to be written.

## Decision

We will write both decks as reveal.js 6.0.2 pages, and commit the seven files a deck loads
into `slides/vendor/reveal/`.

## Consequences

A deck opens from a `file://` path with nothing fetched, so the room's network cannot stop the
talk. `data-line-numbers` on a code block reveals it a line or a range at a time. highlight.js
arrives inside the vendored plugin with every language in it, so `x86asm` works immediately and
ticket 004's arm64 slide needs no extra file. Forth is the one language it does not know, so
`slides/theme/forth-highlight.js` holds a grammar of our own, registered through the plugin's
`beforeHighlight` hook, which is what keeps the vendored file unedited. The costs are that the
talk now needs a browser, with a PDF exported from the print view as the fallback; that 1.2 MB
of someone else's JavaScript sits in a repository of two thousand lines of assembly; and that
an upgrade is a copy of seven named files, written down in `slides/vendor/README.md`.
