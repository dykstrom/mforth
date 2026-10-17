/* test.c - exercise C1: c_to_f() converts Celsius to Fahrenheit. */
#include "../../tools/check.h"

double c_to_f(double c);

/* Every case is one where c * 9 / 5 + 32 and c * 1.8 + 32 arrive at the
 * same double, so either way of writing it passes. 37 is not such a case:
 * the two answers differ in the last bit. */
int main(void)
{
    begin("c_to_f(100)");
    expect_double(c_to_f(100), 212.0);

    begin("c_to_f(0)");
    expect_double(c_to_f(0), 32.0);

    begin("c_to_f(-40)");
    expect_double(c_to_f(-40), -40.0);

    begin("c_to_f(20)");
    expect_double(c_to_f(20), 68.0);

    begin("c_to_f(-17.5)");
    expect_double(c_to_f(-17.5), 0.5);

    /* The number on paper is 33.8, which has no exact binary form. The
     * compiler works it out the same way the SSE instructions do. */
    begin("c_to_f(1)");
    expect_double(c_to_f(1), 1.0 * 9 / 5 + 32);

    /* Absolute zero. On paper -459.67. */
    begin("c_to_f(-273.15)");
    expect_double(c_to_f(-273.15), -273.15 * 9 / 5 + 32);

    return done();
}
