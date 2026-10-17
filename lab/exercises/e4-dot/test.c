/* test.c - exercise E4: . prints, and 2 3 + . prints 5. */
#include "../../tools/check.h"
#include "../../tools/forth.h"

/* The dot's "call printf" arrives here instead of at libc's printf. See
 * "Catching output" in check.h. */
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

/* Run the thread. It passes if it printed what was expected, called printf
 * with the stack aligned, and left what was expected on the stack. */
static void expect_printed(const void *const *thread, const char *printed,
                           const char *left)
{
    static char complaint[512];

    catch_reset();
    const char *stack_left = run(thread);

    int ok = 0;
    if (strcmp(caught, printed) != 0) {
        snprintf(complaint, sizeof complaint,
                 "expected it to print \"%s\", it printed \"%s\"",
                 printed, caught);
    } else if (misaligned_calls > 0) {
        snprintf(complaint, sizeof complaint,
                 "printf was called with rsp not a multiple of 16");
    } else if (strcmp(stack_left, left) != 0) {
        snprintf(complaint, sizeof complaint,
                 "printed the right thing, but left \"%s\" on the stack, "
                 "expected \"%s\"",
                 stack_left, left);
    } else {
        ok = 1;
    }
    expect(ok, complaint);
}

int main(void)
{
    begin("LIT 7 . BYE");
    expect_printed(THREAD(LIT, N(7), DOT, BYE), "7 ", "");

    begin("LIT -7 . BYE");
    expect_printed(THREAD(LIT, N(-7), DOT, BYE), "-7 ", "");

    /* . takes the top item, and the top item is the last one pushed. */
    begin("LIT 1 LIT 2 . . BYE");
    expect_printed(THREAD(LIT, N(1), LIT, N(2), DOT, DOT, BYE), "2 1 ", "");

    begin("LIT 1 LIT 2 LIT 3 . BYE");
    expect_printed(THREAD(LIT, N(1), LIT, N(2), LIT, N(3), DOT, BYE), "3 ",
                   "1 2");

    begin("LIT 2 LIT 3 + . BYE");
    expect_printed(THREAD(LIT, N(2), LIT, N(3), PLUS, DOT, BYE), "5 ", "");

    return done();
}
