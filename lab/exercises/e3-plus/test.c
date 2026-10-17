/* test.c - exercise E3: +. */
#include "../../tools/check.h"
#include "../../tools/forth.h"

int main(void)
{
    begin("LIT 2 LIT 3 + BYE");
    expect_string(run(THREAD(LIT, N(2), LIT, N(3), PLUS, BYE)), "5");

    begin("LIT -4 LIT 3 + BYE");
    expect_string(run(THREAD(LIT, N(-4), LIT, N(3), PLUS, BYE)), "-1");

    /* + touches the top two items only. */
    begin("LIT 7 LIT 2 LIT 3 + BYE");
    expect_string(run(THREAD(LIT, N(7), LIT, N(2), LIT, N(3), PLUS, BYE)),
                  "7 5");

    begin("LIT 1 LIT 2 LIT 3 + + BYE");
    expect_string(run(THREAD(LIT, N(1), LIT, N(2), LIT, N(3), PLUS, PLUS, BYE)),
                  "6");

    begin("LIT 2 DUP + BYE");
    expect_string(run(THREAD(LIT, N(2), DUP, PLUS, BYE)), "4");

    return done();
}
