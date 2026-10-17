# build.sh - what ./check and ./debug share. Sourced by both, not run.
#
# An exercise is a directory exercises/<id>-<name>/. It holds <name>.asm, the
# file the attendee edits; solution.asm; and test.c, which calls the function
# once per case. The function, the file and the directory share the name:
# exercises/c2-average/average.asm defines average.

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
# -no-pie is what lets an address be written "mov rdi, msg" and a libc call
# "call printf", as in the deck. -z noexecstack answers a linker warning that
# nasm objects get by default and that would otherwise turn up in every
# build's errors.
build() {
    mkdir -p "$3"
    nasm -f elf64 -g -F dwarf "$2" -o "$3/$(exercise_function "$1").o" 2> "$3/errors" &&
    clang -no-pie -Wl,-z,noexecstack -g \
        "$1/test.c" "$3/$(exercise_function "$1").o" -o "$3/test" 2>> "$3/errors"
}
