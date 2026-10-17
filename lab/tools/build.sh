# build.sh - what ./check and ./debug share. Sourced by both, not run.
#
# An exercise is a directory exercises/<id>-<name>/. It holds <name>.asm, the
# file the attendee edits; solution.asm; and test.c, which calls the function
# once per case. The function, the file and the directory share the name:
# exercises/c2-average/average.asm defines average. A tier D puzzle is the
# one exception: exercises/d1-phase1/phase1.asm holds the input that the
# function phase1, in puzzle/phase1.asm, has to accept.

# The directory for an exercise id: c2 -> exercises/c2-average.
exercise_dir() {
    for dir in exercises/"$1"-*/; do
        if [ -d "$dir" ]; then
            echo "${dir%/}"
            return 0
        fi
    done
    return 1
}

# The function an exercise asks for: exercises/c2-average -> average.
exercise_function() {
    echo "${1#*/*-}"
}

# build <exercise dir> <source.asm> <output dir>
#
# Assembles the source and links it with the exercise's test into
# <output dir>/test. Whatever nasm and clang say goes to <output dir>/errors.
#
# -g -F dwarf makes nasm record which line of the .asm each instruction came
# from, which is what lets gdb show the source while it steps.
#
# A tier D exercise is a puzzle: <name>.asm holds the attendee's answer, and
# the function that judges it is puzzle/<name>.asm. That one is assembled
# without -g, so gdb has only the machine code to show.
#
# -no-pie is what lets an address be written "mov rdi, msg" and a libc call
# "call printf", as in the deck. -z noexecstack answers a linker warning that
# nasm objects get by default and that would otherwise turn up in every
# build's errors.
#
# -fno-builtin stops clang treating a name like strlen or hypot as the
# libc function it knows. A test declares those names for the attendee's
# functions, and calls them; clang must not work the answer out itself, or
# warn that the declaration differs from libc's.
build() {
    function=$(exercise_function "$1")
    mkdir -p "$3"
    nasm -f elf64 -g -F dwarf "$2" -o "$3/$function.o" 2> "$3/errors" || return 1
    objects="$3/$function.o"
    if [ -f "puzzle/$function.asm" ]; then
        nasm -f elf64 "puzzle/$function.asm" -o "$3/puzzle.o" 2>> "$3/errors" || return 1
        objects="$objects $3/puzzle.o"
    fi
    clang -no-pie -Wl,-z,noexecstack -g -fno-builtin \
        "$1/test.c" $objects -o "$3/test" 2>> "$3/errors"
}
