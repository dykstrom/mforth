/* test.c - exercise B3: sum_squares() calls square() and keeps rbx. */
#include "../../tools/check.h"

long sum_squares(long n);

static int calls;
static int misaligned;

/* The square function sum_squares calls. Besides the square, it does two
 * things a real function is allowed to do and a quiet one usually doesn't:
 * it notes whether the call was aligned, and it fills every caller-saved
 * register with 0xbad. A count or a sum kept in one of them is lost at
 * every call, and gdb shows what replaced it. */
long square(long x)
{
    calls++;
    if (!CALLED_ALIGNED()) {
        misaligned++;
    }
    asm volatile(".intel_syntax noprefix\n\t"
                 "mov     rdi, 0xbad\n\t"
                 "mov     rsi, 0xbad\n\t"
                 "mov     rdx, 0xbad\n\t"
                 "mov     rcx, 0xbad\n\t"
                 "mov     r8, 0xbad\n\t"
                 "mov     r9, 0xbad\n\t"
                 "mov     r10, 0xbad\n\t"
                 "mov     r11, 0xbad\n\t"
                 ".att_syntax"
                 ::: "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11");
    return x * x;
}

/* The callee-saved registers, in the order call_checked() below reports
 * them, and the value it puts in each before the call. */
static const char *names[] = { "rbx", "rbp", "r12", "r13", "r14", "r15" };
static const long before[] = { 0x1b, 0x1d, 0x12, 0x13, 0x14, 0x15 };

/* long call_checked(long n, long after[6]);
 *
 * Calls sum_squares(n), and returns what it returns. A function written in
 * assembly, here in the test, because C has no way to say "put this in
 * rbx". It loads the values in before[] into the callee-saved registers,
 * makes the call, and writes what the registers hold afterwards to after[].
 * It has to keep the rule itself, so it saves the C caller's values first
 * and gives them back at the end. */
long call_checked(long n, long *after);
asm(".intel_syntax noprefix\n"
    "        .text\n"
    "call_checked:\n"
    "        push    rbx\n"              /* the C caller's values */
    "        push    rbp\n"
    "        push    r12\n"
    "        push    r13\n"
    "        push    r14\n"
    "        push    r15\n"
    "        push    rsi\n"              /* after, for when the call is done.
                                          * 7 pushes and the return address:
                                          * 64 bytes, so rsp is aligned */
    "        mov     rbx, 0x1b\n"        /* the values in before[] */
    "        mov     rbp, 0x1d\n"
    "        mov     r12, 0x12\n"
    "        mov     r13, 0x13\n"
    "        mov     r14, 0x14\n"
    "        mov     r15, 0x15\n"
    "        call    sum_squares\n"      /* n is still in rdi */
    "        pop     rsi\n"
    "        mov     [rsi], rbx\n"       /* what came back */
    "        mov     [rsi + 8], rbp\n"
    "        mov     [rsi + 16], r12\n"
    "        mov     [rsi + 24], r13\n"
    "        mov     [rsi + 32], r14\n"
    "        mov     [rsi + 40], r15\n"
    "        pop     r15\n"
    "        pop     r14\n"
    "        pop     r13\n"
    "        pop     r12\n"
    "        pop     rbp\n"
    "        pop     rbx\n"
    "        ret\n"                      /* sum_squares' answer is still in rax */
    ".att_syntax\n");

/* The first register sum_squares did not give back, as a complaint. */
static char changed[128];

static void sum(long n, long expected)
{
    char call[64];
    long after[6];

    snprintf(call, sizeof call, "sum_squares(%ld)", n);
    begin(call);
    expect_long(call_checked(n, after), expected);

    for (int i = 0; i < 6 && changed[0] == '\0'; i++) {
        if (after[i] != before[i]) {
            snprintf(changed, sizeof changed,
                     "%s was %#lx before %s and %#lx after it",
                     names[i], before[i], call, after[i]);
        }
    }
}

int main(void)
{
    sum(0, 0);
    sum(1, 1);
    sum(3, 14);
    sum(10, 385);
    sum(100, 338350);

    begin("rbx, rbp and r12 to r15 kept");
    expect(changed[0] == '\0', changed);

    long after[6];
    calls = 0;
    call_checked(10, after);
    begin("sum_squares(10) called square");
    if (calls == 10) {
        expect(1, "");
    } else {
        char complaint[64];
        snprintf(complaint, sizeof complaint, "expected 10 calls, got %d", calls);
        expect(0, complaint);
    }

    begin("rsp at call square");
    if (calls == 0) {
        expect(0, "square was never called");
    } else {
        expect(misaligned == 0,
               "8 bytes off a multiple of 16: the 16-byte rule in the tier notes");
    }

    return done();
}
