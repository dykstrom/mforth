/* test.c - exercise A1: add() of two longs. */
#include "../../tools/check.h"

long add(long a, long b);

int main(void)
{
    begin("add(2, 3)");
    expect_long(add(2, 3), 5);

    begin("add(0, 0)");
    expect_long(add(0, 0), 0);

    begin("add(-7, 3)");
    expect_long(add(-7, 3), -4);

    begin("add(-1, -1)");
    expect_long(add(-1, -1), -2);

    /* Too big for 32 bits: a sum done in eax would lose the top half. */
    begin("add(4000000000, 5000000000)");
    expect_long(add(4000000000, 5000000000), 9000000000);

    return done();
}
