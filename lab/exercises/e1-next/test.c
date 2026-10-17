/* test.c - exercise E1: NEXT runs a thread of LITs to the end. */
#include "../../tools/check.h"
#include "../../tools/forth.h"

int main(void)
{
    /* BYE is the first word, so this one passes with or without NEXT. */
    begin("BYE");
    expect_string(run(THREAD(BYE)), "");

    begin("LIT 2 BYE");
    expect_string(run(THREAD(LIT, N(2), BYE)), "2");

    begin("LIT 2 LIT 3 BYE");
    expect_string(run(THREAD(LIT, N(2), LIT, N(3), BYE)), "2 3");

    begin("LIT -1 LIT 0 BYE");
    expect_string(run(THREAD(LIT, N(-1), LIT, N(0), BYE)), "-1 0");

    begin("LIT 1 LIT 2 LIT 3 LIT 4 LIT 5 BYE");
    expect_string(run(THREAD(LIT, N(1), LIT, N(2), LIT, N(3), LIT, N(4),
                             LIT, N(5), BYE)),
                  "1 2 3 4 5");

    return done();
}
