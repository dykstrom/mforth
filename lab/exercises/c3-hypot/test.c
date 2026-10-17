/* test.c - exercise C3: hypot() of two sides. */
#include "../../tools/check.h"

/* libc has a hypot too, in libm. The test is not linked with libm, and is
 * built with -fno-builtin, so this hypot is the one in hypot.asm. */
double hypot(double x, double y);

int main(void)
{
    begin("hypot(3, 4)");
    expect_double(hypot(3, 4), 5.0);

    begin("hypot(5, 12)");
    expect_double(hypot(5, 12), 13.0);

    begin("hypot(8, 15)");
    expect_double(hypot(8, 15), 17.0);

    /* Squaring makes the sign go away. */
    begin("hypot(-3, 4)");
    expect_double(hypot(-3, 4), 5.0);

    begin("hypot(-5, -12)");
    expect_double(hypot(-5, -12), 13.0);

    /* The square root of 2, rounded to the nearest double. sqrtsd always
     * rounds to the nearest, so there is only one right answer. */
    begin("hypot(1, 1)");
    expect_double(hypot(1, 1), 1.4142135623730951);

    begin("hypot(0, 0)");
    expect_double(hypot(0, 0), 0.0);

    return done();
}
