/* test.c - exercise B2: show_sum() prints a sum with printf. */
#include "../../tools/check.h"

void show_sum(long a, long b);

static int calls;
static int nonzero_al;
static int misaligned;

/* al at the last call to printf. Not static: the assembly below writes it. */
unsigned char al_at_call;

/* show_sum's "call printf" arrives here instead of at libc's printf. See
 * "Catching output" in check.h.
 *
 * It starts with two instructions of assembly, because C cannot see al,
 * which tells a function like printf how many xmm registers hold arguments.
 * They keep al, then jump on to catch_printf below. A jump pushes nothing,
 * so catch_printf finds every register, and rsp, as the call left them. */
__attribute__((naked)) int printf(const char *format, ...)
{
    asm(".intel_syntax noprefix\n\t"
        "mov     byte ptr [rip + al_at_call], al\n\t"
        "jmp     catch_printf\n\t"
        ".att_syntax");
}

int catch_printf(const char *format, ...)
{
    char text[256];
    va_list args;

    calls++;
    if (al_at_call != 0) {
        nonzero_al = al_at_call;
    }
    catch_alignment(CALLED_ALIGNED());

    va_start(args, format);
    vsnprintf(text, sizeof text, format, args);
    va_end(args);
    catch_text(text);
    return (int) strlen(text);
}

static void show(long a, long b, const char *expected)
{
    char call[64];

    snprintf(call, sizeof call, "show_sum(%ld, %ld)", a, b);
    catch_reset();
    begin(call);
    show_sum(a, b);
    expect_string(caught, expected);
    misaligned += misaligned_calls;
}

int main(void)
{
    show(2, 3, "2 + 3 = 5\n");
    show(-7, 10, "-7 + 10 = 3\n");
    show(0, 0, "0 + 0 = 0\n");
    show(1000000, 2345678, "1000000 + 2345678 = 3345678\n");

    begin("al at call printf");
    if (calls == 0) {
        expect(0, "printf was never called");
    } else {
        char complaint[128];
        snprintf(complaint, sizeof complaint,
                 "it was %d. No argument is in an xmm register, so it should be 0",
                 nonzero_al);
        expect(nonzero_al == 0, complaint);
    }

    begin("rsp at call printf");
    if (calls == 0) {
        expect(0, "printf was never called");
    } else {
        expect(misaligned == 0,
               "8 bytes off a multiple of 16: the 16-byte rule in the tier notes");
    }

    return done();
}
