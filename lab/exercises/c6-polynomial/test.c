/* test.c - exercise C6: polynomial() by Horner's rule. */
#include "../../tools/check.h"

double polynomial(const double *c, long n, double x);

/* Every coefficient and every x here is a small whole number or a power of
 * two, so every product and sum is exact. Horner's rule and adding up the
 * powers of x one by one then give the same double. */
int main(void)
{
    begin("polynomial({5}, 1, 3)");
    expect_double(polynomial((double[]){5}, 1, 3), 5.0);

    /* 1 + 2*2 + 3*4 */
    begin("polynomial({1, 2, 3}, 3, 2)");
    expect_double(polynomial((double[]){1, 2, 3}, 3, 2), 17.0);

    /* Only c[0] is left when x is 0. */
    begin("polynomial({1, 2, 3}, 3, 0)");
    expect_double(polynomial((double[]){1, 2, 3}, 3, 0), 1.0);

    /* x squared, with x = -3. */
    begin("polynomial({0, 0, 1}, 3, -3)");
    expect_double(polynomial((double[]){0, 0, 1}, 3, -3), 9.0);

    /* 1 - 2 + 4 - 8 */
    begin("polynomial({1, -1, 1, -1}, 4, 2)");
    expect_double(polynomial((double[]){1, -1, 1, -1}, 4, 2), -5.0);

    /* 2 + 0.5^5, which is 2 + 1/32 */
    begin("polynomial({2, 0, 0, 0, 0, 1}, 6, 0.5)");
    expect_double(polynomial((double[]){2, 0, 0, 0, 0, 1}, 6, 0.5), 2.03125);

    /* 1 + 2 + 4 + ... + 512 */
    begin("polynomial({1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, 10, 2)");
    expect_double(polynomial((double[]){1, 1, 1, 1, 1, 1, 1, 1, 1, 1}, 10, 2), 1023.0);

    /* n is 0, so the 99 must not be read. */
    begin("polynomial({}, 0, 7)");
    expect_double(polynomial((double[]){99}, 0, 7), 0.0);

    return done();
}
