# Build mforth. Linux/x86_64 only: see docs/architecture/design-goals.md.
#
# Run this on a Linux/x86_64 machine, or inside a container with nasm and
# clang; README.md shows both. This file invokes nothing but nasm and clang.

NASM      = nasm
NASMFLAGS = -f elf64
CC        = clang

# -no-pie is load-bearing, not packaging. See docs/adr/0001-link-non-pie.md.
LDFLAGS   = -no-pie

# nasm is invoked on src/mforth.asm alone; every other source file arrives
# there through %include. They are all listed as prerequisites so that
# editing any one of them rebuilds the object file.
SOURCES = $(wildcard src/*.asm) $(wildcard include/*.inc)

all: build/mforth

build/mforth: build/mforth.o
	$(CC) $(LDFLAGS) $< -o $@

build/mforth.o: $(SOURCES) | build
	$(NASM) $(NASMFLAGS) src/mforth.asm -o $@

# An order-only prerequisite: make creates the directory if it is missing,
# but does not rebuild the object file when the directory's timestamp
# changes.
build:
	mkdir -p build

test: all
	tests/run.sh

# The prelude and the terminal are one stream on standard input: the file goes
# first and then what is typed. The words the prelude defines are there before
# anyone types, and Ctrl-D still ends the session. mforth has no word that
# loads a file; the shell does the work.
#
# The terminal half goes through "sed -u" and not through the "-" argument of
# cat. The cat on Ubuntu 26.04 is the Rust uutils one, and when its output is a
# pipe it holds what it reads from the terminal until the buffer fills, so a
# line typed here would not reach mforth until Ctrl-D. sed -u copies its input
# through and flushes it a line at a time, which is what an interpreter that
# answers one line at a time needs. The empty script '' tells sed to change
# nothing on the way past.
run: all
	{ cat lib/prelude.f; sed -u ''; } | ./build/mforth

clean:
	rm -rf build

.PHONY: all test run clean
