/* test.c - exercise C4: clamp() keeps x between lo and hi. */
#include "../../tools/check.h"

double clamp(double x, double lo, double hi);

int main(void)
{
    /* jg after ucomisd is taken whenever the two differ, so a jg for "above
     * hi" clamps this one, and every other x in range, to hi. */
    begin("clamp(5, 0, 10)");
    expect_double(clamp(5, 0, 10), 5.0);

    /* jl after ucomisd is never taken, so a jl for "below lo" lets this
     * one through. */
    begin("clamp(-3, 0, 10)");
    expect_double(clamp(-3, 0, 10), 0.0);

    begin("clamp(12, 0, 10)");
    expect_double(clamp(12, 0, 10), 10.0);

    begin("clamp(0, 0, 10)");
    expect_double(clamp(0, 0, 10), 0.0);

    begin("clamp(10, 0, 10)");
    expect_double(clamp(10, 0, 10), 10.0);

    begin("clamp(-7.5, -5, 5)");
    expect_double(clamp(-7.5, -5, 5), -5.0);

    begin("clamp(0.25, -5, 5)");
    expect_double(clamp(0.25, -5, 5), 0.25);

    begin("clamp(infinity, 0, 1)");
    expect_double(clamp(__builtin_inf(), 0, 1), 1.0);

    begin("clamp(-infinity, 0, 1)");
    expect_double(clamp(-__builtin_inf(), 0, 1), 0.0);

    /* A NaN is neither below lo nor above hi. ucomisd sets CF for it, the
     * same flag as "below", so a jb with no jp before it returns lo. */
    begin("clamp(NaN, 0, 1)");
    expect_double(clamp(__builtin_nan(""), 0, 1), __builtin_nan(""));

    return done();
}
