#!/bin/sh
#
# Runs every mforth test and reports one line per test. Called by "make
# test" from the repository root, which is where the paths below start.
#
# A test is a file tests/<name>.expected holding the output mforth must
# produce. lib/prelude.f is fed to mforth first, the way "make run" feeds
# it, so a test may use the words defined there. tests/<name>.f follows
# when it exists; otherwise mforth reaches the end of the input after the
# prelude and leaves.
#
# The prelude answers every one of its own lines with " ok", so each
# .expected file begins with the banner and then that block.

set -u

mforth=build/mforth
failed=0

for expected in tests/*.expected; do
    name=$(basename "$expected" .expected)

    input=tests/$name.f
    if [ ! -f "$input" ]; then
        input=/dev/null
    fi

    actual=$(mktemp)
    cat lib/prelude.f "$input" | "$mforth" > "$actual"

    if diff -u "$expected" "$actual"; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        failed=1
    fi

    rm -f "$actual"
done

exit $failed
