#!/bin/sh
#
# Runs every mforth test and reports one line per test. Called by "make
# test" from the repository root, which is where the paths below start.
#
# A test is a file tests/<name>.expected holding the output mforth must
# produce. When tests/<name>.f exists, it is fed to mforth on standard
# input; otherwise mforth reads nothing, which it takes as end of input
# and leaves at once.

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
    "$mforth" < "$input" > "$actual"

    if diff -u "$expected" "$actual"; then
        echo "ok   $name"
    else
        echo "FAIL $name"
        failed=1
    fi

    rm -f "$actual"
done

exit $failed
