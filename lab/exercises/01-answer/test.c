/* test.c - exercise 01: answer() returns 42. */
#include "../../tools/check.h"

long answer(void);

int main(void)
{
    begin("answer()");
    expect_long(answer(), 42);

    return done();
}
