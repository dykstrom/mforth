/* test.c - exercise E2: DUP and SWAP. */
#include "../../tools/check.h"
#include "../../tools/forth.h"

int main(void)
{
    begin("LIT 2 DUP BYE");
    expect_string(run(THREAD(LIT, N(2), DUP, BYE)), "2 2");

    begin("LIT 1 LIT 2 DUP BYE");
    expect_string(run(THREAD(LIT, N(1), LIT, N(2), DUP, BYE)), "1 2 2");

    begin("LIT 2 LIT 3 SWAP BYE");
    expect_string(run(THREAD(LIT, N(2), LIT, N(3), SWAP, BYE)), "3 2");

    /* SWAP touches the top two items only. */
    begin("LIT 1 LIT 2 LIT 3 SWAP BYE");
    expect_string(run(THREAD(LIT, N(1), LIT, N(2), LIT, N(3), SWAP, BYE)),
                  "1 3 2");

    begin("LIT 1 LIT 2 LIT 3 SWAP DUP BYE");
    expect_string(run(THREAD(LIT, N(1), LIT, N(2), LIT, N(3), SWAP, DUP, BYE)),
                  "1 3 2 2");

    /* SWAP twice is no SWAP at all. */
    begin("LIT 2 LIT 3 SWAP SWAP BYE");
    expect_string(run(THREAD(LIT, N(2), LIT, N(3), SWAP, SWAP, BYE)), "2 3");

    return done();
}
