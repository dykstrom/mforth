// rmw-arm64.s - the same work on arm64, where it takes three instructions.
//
// arm64 is a load/store architecture: arithmetic happens between registers,
// and memory is reached only by a load or a store. The one x86-64
// instruction "add [rax], rbx" becomes ldr, add, str - read it, add it,
// write it back, each step named.
//
// This file is here to be read next to rmw-x86.asm. It is not linked into
// anything. It assembles on an arm64 machine, which is what the macOS host
// is:
//
//     clang -c rmw-arm64.s -o rmw-arm64.o
//
// The syntax is the assembler clang carries, not NASM's: comments start
// with //, directives start with a dot, and the destination register is
// written first.

        .text
        .globl  _rmw                    // macOS puts an underscore in front
                                        // of a C name; on Linux it is "rmw"
        .align  2

// void rmw(long *cell, long n) - add n into the cell at the address.
// The first two arguments arrive in x0 and x1.
_rmw:
        ldr     x2, [x0]                // read the cell into a register
        add     x2, x2, x1              // add, register to register
        str     x2, [x0]                // write the sum back
        ret
