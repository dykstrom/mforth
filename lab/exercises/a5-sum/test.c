/* test.c - exercise A5: sum() of n longs. */
#include "../../tools/check.h"

long sum(const long *a, long n);

int main(void)
{
    begin("sum({1, 2, 3}, 3)");
    expect_long(sum((long[]){1, 2, 3}, 3), 6);

    begin("sum({42}, 1)");
    expect_long(sum((long[]){42}, 1), 42);

    begin("sum({5, -2, -10}, 3)");
    expect_long(sum((long[]){5, -2, -10}, 3), -7);

    /* n is 2, so the 1000 past the end must not be added. */
    begin("sum({1, 2}, 2)");
    expect_long(sum((long[]){1, 2, 1000}, 2), 3);

    /* n is 0, so the 99 must not be read. */
    begin("sum({}, 0)");
    expect_long(sum((long[]){99}, 0), 0);

    /* Too big for 32 bits: an add into eax would lose the top half. */
    begin("sum({3000000000, 3000000000}, 2)");
    expect_long(sum((long[]){3000000000, 3000000000}, 2), 6000000000);

    long hundred[100];
    for (int i = 0; i < 100; i++) {
        hundred[i] = i + 1;
    }
    begin("sum({1, 2, ..., 100}, 100)");
    expect_long(sum(hundred, 100), 5050);

    return done();
}
