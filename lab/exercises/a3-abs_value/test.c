/* test.c - exercise A3: abs_value() of a signed long. */
#include <limits.h>
#include "../../tools/check.h"

long abs_value(long x);

int main(void)
{
    begin("abs_value(5)");
    expect_long(abs_value(5), 5);

    begin("abs_value(-5)");
    expect_long(abs_value(-5), 5);

    begin("abs_value(0)");
    expect_long(abs_value(0), 0);

    begin("abs_value(-1)");
    expect_long(abs_value(-1), 1);

    /* Too big for 32 bits: neg of eax would lose the top half. */
    begin("abs_value(-10000000000)");
    expect_long(abs_value(-10000000000), 10000000000);

    /* The most negative long has no positive twin: 2 to the 63 needs one
     * bit more than a long has. neg gives the number back unchanged. */
    begin("abs_value(-9223372036854775808)");
    expect_long(abs_value(LONG_MIN), LONG_MIN);

    return done();
}
