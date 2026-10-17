/* test.c - exercise C7: dot() of two float arrays. */
#include "../../tools/check.h"

float dot(const float *a, const float *b, long n);

/* Every array starts on a 16-byte boundary, so movaps, and mulps with a
 * memory operand, may read them.
 *
 * Every value is a whole number or a half, and every sum stays far below
 * 2^24, where floats stop holding every whole number. So the products and
 * sums are exact, and adding the four lanes in any order gives the same
 * float. */
static _Alignas(16) float ones[8] = {1, 1, 1, 1, 1, 1, 1, 1};
static _Alignas(16) float up[8] = {1, 2, 3, 4, 5, 6, 7, 8};
static _Alignas(16) float down[4] = {4, 3, 2, 1};
static _Alignas(16) float halves[4] = {0.5, 1.5, 2.5, 3.5};
static _Alignas(16) float signs[4] = {1, -1, 1, -1};

/* Four elements to use, and four 99s past them that must not be read. */
static _Alignas(16) float short_a[8] = {1, 2, 3, 4, 99, 99, 99, 99};
static _Alignas(16) float short_b[8] = {1, 1, 1, 1, 99, 99, 99, 99};

static _Alignas(16) float hundred[100];
static _Alignas(16) float alternate[100];

int main(void)
{
    begin("dot({1, 2, 3, 4}, {1, 1, 1, 1}, 4)");
    expect_double(dot(up, ones, 4), 10.0);

    begin("dot({1, 2, 3, 4}, {4, 3, 2, 1}, 4)");
    expect_double(dot(up, down, 4), 20.0);

    begin("dot({0.5, 1.5, 2.5, 3.5}, {1, -1, 1, -1}, 4)");
    expect_double(dot(halves, signs, 4), -2.0);

    begin("dot({1, 2, ..., 8}, {1, 1, ..., 1}, 8)");
    expect_double(dot(up, ones, 8), 36.0);

    begin("dot({1, 2, ..., 8}, {1, 2, ..., 8}, 8)");
    expect_double(dot(up, up, 8), 204.0);

    begin("dot({1, 2, 3, 4, 99, ...}, {1, 1, 1, 1, 99, ...}, 4)");
    expect_double(dot(short_a, short_b, 4), 10.0);

    begin("dot({}, {}, 0)");
    expect_double(dot(short_a + 4, short_b + 4, 0), 0.0);

    for (int i = 0; i < 100; i++) {
        hundred[i] = i + 1;
        alternate[i] = i % 2 == 0 ? 1 : -1;
    }

    /* 1*1 + 2*2 + ... + 100*100 */
    begin("dot({1, 2, ..., 100}, {1, 2, ..., 100}, 100)");
    expect_double(dot(hundred, hundred, 100), 338350.0);

    /* 1 - 2 + 3 - 4 + ... - 100 */
    begin("dot({1, 2, ..., 100}, {1, -1, 1, -1, ...}, 100)");
    expect_double(dot(hundred, alternate, 100), -50.0);

    return done();
}
