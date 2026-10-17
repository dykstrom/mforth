/* test.c - exercise A2: max() of two signed longs. */
#include "../../tools/check.h"

long max(long a, long b);

int main(void)
{
    begin("max(2, 3)");
    expect_long(max(2, 3), 3);

    begin("max(3, 2)");
    expect_long(max(3, 2), 3);

    begin("max(5, 5)");
    expect_long(max(5, 5), 5);

    /* Read as unsigned, -1 is the largest number there is. These two
     * catch a ja or jb where a jg or jl belongs. */
    begin("max(-1, 0)");
    expect_long(max(-1, 0), 0);

    begin("max(0, -1)");
    expect_long(max(0, -1), 0);

    begin("max(-8, -3)");
    expect_long(max(-8, -3), -3);

    /* Too big for 32 bits: a comparison of edi and esi would get it wrong. */
    begin("max(4294967296, 1)");
    expect_long(max(4294967296, 1), 4294967296);

    return done();
}
