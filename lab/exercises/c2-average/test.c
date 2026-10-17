/* test.c - exercise C2: average() of n doubles. */
#include "../../tools/check.h"

double average(const double *a, long n);

int main(void)
{
    begin("average({1, 2, 3}, 3)");
    expect_double(average((double[]){1, 2, 3}, 3), 2.0);

    begin("average({2.5}, 1)");
    expect_double(average((double[]){2.5}, 1), 2.5);

    begin("average({1, 2, 3, 4}, 4)");
    expect_double(average((double[]){1, 2, 3, 4}, 4), 2.5);

    begin("average({-1.5, 1.5}, 2)");
    expect_double(average((double[]){-1.5, 1.5}, 2), 0.0);

    /* The number on paper is 0.15. The one the hardware arrives at is
     * not, because neither 0.1 nor 0.2 has an exact binary form. The
     * compiler works it out the same way the SSE instructions do. */
    begin("average({0.1, 0.2}, 2)");
    expect_double(average((double[]){0.1, 0.2}, 2), (0.1 + 0.2) / 2);

    /* n is 0, so the 99 must not be read. */
    begin("average({}, 0)");
    expect_double(average((double[]){99}, 0), 0.0);

    double hundred[100];
    for (int i = 0; i < 100; i++) {
        hundred[i] = i + 1;
    }
    begin("average({1, 2, ..., 100}, 100)");
    expect_double(average(hundred, 100), 50.5);

    return done();
}
