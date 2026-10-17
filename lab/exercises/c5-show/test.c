/* test.c - exercise C5: show() prints a label and a double with printf. */
#include "../../tools/check.h"

void show(const char *label, double x);

/* The call printf in show.asm arrives here instead of at libc's printf.
 * This one formats the text the same way, with vsnprintf, and keeps it for
 * the test to compare rather than printing it. It also notes whether rsp was
 * a multiple of 16 at the call.
 *
 * Built by clang, it reads its double arguments the way libc's printf does:
 * from the xmm registers only when al says there are any. */
int printf(const char *format, ...)
{
    char text[256];
    va_list args;

    catch_alignment(CALLED_ALIGNED());
    va_start(args, format);
    int length = vsnprintf(text, sizeof text, format, args);
    va_end(args);
    catch_text(text);
    return length;
}

/* One case: call show, then compare what it printed. A misaligned call is
 * reported first, because it is the mistake that can crash elsewhere,
 * while the text still comes out right on this machine. */
static void check(const char *call, const char *label, double x, const char *expected)
{
    begin(call);
    catch_reset();
    show(label, x);
    if (misaligned_calls > 0) {
        expect(0, "rsp was not a multiple of 16 at call printf");
    } else {
        expect_string(caught, expected);
    }
}

int main(void)
{
    check("show(\"pi\", 3.14159)", "pi", 3.14159, "pi = 3.14\n");
    check("show(\"half\", 0.5)", "half", 0.5, "half = 0.50\n");
    check("show(\"x\", -2.25)", "x", -2.25, "x = -2.25\n");
    check("show(\"big\", 1234.5678)", "big", 1234.5678, "big = 1234.57\n");
    check("show(\"zero\", 0)", "zero", 0, "zero = 0.00\n");

    return done();
}
