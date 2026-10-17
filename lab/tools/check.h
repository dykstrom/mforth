/* check.h - the few lines every exercise's test.c shares.
 *
 * A test calls the attendee's function once per case and prints one line for
 * each:
 *
 *     average({1, 2, 3}, 3) ... ok
 *     average({2.5}, 1) ... expected 2.5, got 0
 *
 * The first half of the line, the call, is printed and flushed before the
 * call is made. If the function crashes, the last thing on the screen is the
 * case that crashed it, and ./check reports that case by name.
 */
#include <stdio.h>

static int cases;
static int failures;

/* Start a case: print the call being made. */
static void begin(const char *call)
{
    cases++;
    printf("%s ... ", call);
    fflush(stdout);
}

static void expect_long(long got, long expected)
{
    if (got == expected) {
        printf("ok\n");
    } else {
        printf("expected %ld, got %ld\n", expected, got);
        failures++;
    }
}

/* Doubles are compared exactly. Every expected value is one the obvious
 * sequence of SSE instructions arrives at; where that is not the number on
 * paper, as with 0.1 + 0.2, the line shows both to 17 digits, which is enough
 * to tell any two doubles apart. A NaN never equals anything, itself
 * included, so a NaN expected is a NaN accepted. */
static void expect_double(double got, double expected)
{
    if (got == expected || (got != got && expected != expected)) {
        printf("ok\n");
    } else {
        printf("expected %.17g, got %.17g\n", expected, got);
        failures++;
    }
}

/* End the test: the tally, and an exit status ./check reads. */
static int done(void)
{
    printf("%d of %d passed\n", cases - failures, cases);
    return failures == 0 ? 0 : 1;
}
