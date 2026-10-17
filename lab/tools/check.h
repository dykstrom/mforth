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
 *
 * Everything here prints with fprintf and fputs, never printf or puts. A
 * test whose function calls puts or printf defines its own of that name, to
 * see what the function printed (see "Catching output" below), and the lines
 * the test prints itself must not land there too.
 */
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

static int cases;
static int failures;

/* Start a case: print the call being made. */
static void begin(const char *call)
{
    cases++;
    fprintf(stdout, "%s ... ", call);
    fflush(stdout);
}

/* The case passed if ok is true. Otherwise the complaint says what went
 * wrong, in the words of the case. */
static void expect(int ok, const char *complaint)
{
    if (ok) {
        fputs("ok\n", stdout);
    } else {
        fprintf(stdout, "%s\n", complaint);
        failures++;
    }
}

static void expect_long(long got, long expected)
{
    if (got == expected) {
        fputs("ok\n", stdout);
    } else {
        fprintf(stdout, "expected %ld, got %ld\n", expected, got);
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
        fputs("ok\n", stdout);
    } else {
        fprintf(stdout, "expected %.17g, got %.17g\n", expected, got);
        failures++;
    }
}

/* Strings are shown in quotes, so that a missing or extra space or newline
 * can be seen. A newline is shown as \n. */
static void show_string(const char *s)
{
    fputc('"', stdout);
    for (; *s; s++) {
        if (*s == '\n') {
            fputs("\\n", stdout);
        } else {
            fputc(*s, stdout);
        }
    }
    fputc('"', stdout);
}

static void expect_string(const char *got, const char *expected)
{
    if (strcmp(got, expected) == 0) {
        fputs("ok\n", stdout);
    } else {
        fputs("expected ", stdout);
        show_string(expected);
        fputs(", got ", stdout);
        show_string(got);
        fputc('\n', stdout);
        failures++;
    }
}

/* End the test: the tally, and an exit status ./check reads. */
static int done(void)
{
    fprintf(stdout, "%d of %d passed\n", cases - failures, cases);
    return failures == 0 ? 0 : 1;
}


/* Catching output --------------------------------------------------------
 *
 * A function that calls puts or printf would print in the middle of the
 * test's own line. So the test defines a puts or printf of its own, which
 * the function's "call puts" reaches instead of libc's: the linker finds a
 * definition in the program itself before it looks in a library. That one
 * keeps the text in caught[] for the test to compare, and notes whether the
 * stack was aligned when it was called.
 */
static char caught[1024];
static int misaligned_calls;

/* Forget what was caught: call before each case. */
static void catch_reset(void)
{
    caught[0] = '\0';
    misaligned_calls = 0;
}

/* Keep text the function printed. */
static void catch_text(const char *text)
{
    strncat(caught, text, sizeof caught - strlen(caught) - 1);
}

/* True when the call that entered the function this is written in was made
 * with rsp a multiple of 16, as the System V ABI asks of every call.
 *
 * The call pushes the return address, eight bytes, and the function's first
 * instruction pushes rbp, eight more. So rbp, the frame address, is a
 * multiple of 16 exactly when rsp was one at the call. Every test is built
 * without optimisation, so every function sets rbp up that way. */
#define CALLED_ALIGNED() (((unsigned long) __builtin_frame_address(0) & 15) == 0)

/* Note one call's alignment: inside the catching puts or printf, as
 * catch_alignment(CALLED_ALIGNED()). */
static void catch_alignment(int aligned)
{
    if (!aligned) {
        misaligned_calls++;
    }
}
