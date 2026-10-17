/* test.c - exercise B4: factorial() of 0 to 20. */
#include "../../tools/check.h"

long factorial(long n);

static void fact(long n, long expected)
{
    char call[64];

    snprintf(call, sizeof call, "factorial(%ld)", n);
    begin(call);
    expect_long(factorial(n), expected);
}

int main(void)
{
    fact(0, 1);
    fact(1, 1);
    fact(2, 2);
    fact(3, 6);
    fact(5, 120);
    fact(10, 3628800);

    /* The largest n whose factorial fits in a long. 21! does not: it
     * needs 66 bits. */
    fact(20, 2432902008176640000);

    return done();
}
