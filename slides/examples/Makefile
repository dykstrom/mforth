# Build the programs the assembly deck quotes. Each one really runs; the
# deck shows the source and the output side by side.
#
# The three x86-64 programs build in the same container that builds mforth:
#
#     docker exec -w /Workspace/mforth/slides/examples \
#         nasm-docker-amd64 make run
#
# rmw-arm64.s is not built here and is not part of "all". It is an arm64
# source kept to be read beside rmw-x86.asm, and it assembles on the macOS
# host, where clang is an arm64 compiler:
#
#     make rmw-arm64.o
#
# Nothing above this directory builds any of it: the top-level Makefile does
# not look in slides/.

NASM      = nasm
NASMFLAGS = -f elf64
CC        = clang

# -no-pie is load-bearing here for the same reason it is in the top-level
# Makefile: it is what lets an address be written "mov rdi, msg" and a libc
# call "call puts". See ../../docs/adr/0001-link-non-pie.md.
LDFLAGS   = -no-pie

PROGRAMS  = exit-syscall hello-syscall hello-libc rmw-x86

all: $(PROGRAMS)

# No libc in these two. -nostdlib leaves out the C runtime and the C library,
# which is why they need their own _start and have to call exit themselves.
exit-syscall: exit-syscall.o
	$(CC) $(LDFLAGS) -nostdlib $< -o $@

hello-syscall: hello-syscall.o
	$(CC) $(LDFLAGS) -nostdlib $< -o $@

hello-libc: hello-libc.o
	$(CC) $(LDFLAGS) $< -o $@

rmw-x86: rmw-x86.o
	$(CC) $(LDFLAGS) $< -o $@

%.o: %.asm
	$(NASM) $(NASMFLAGS) $< -o $@

# The arm64 file, assembled by clang and not by nasm. An object file is as
# far as it goes: there is no main here to link.
rmw-arm64.o: rmw-arm64.s
	$(CC) -c $< -o $@

# Run them all, so the output in README.md can be checked against what they
# actually print. exit-syscall prints nothing, so its exit status is what
# there is to see.
run: all
	./exit-syscall; echo "exit-syscall exit $$?"
	./hello-syscall
	./hello-libc
	./rmw-x86

clean:
	rm -f *.o $(PROGRAMS)

.PHONY: all run clean
