/* test.c - puzzle D1: does phase1 accept the input in phase1.asm? */
#include "../../tools/check.h"

int phase1(const char *input);
extern const char input[];

int main(void)
{
    char call[200];
    snprintf(call, sizeof call, "phase1(\"%s\")", input);

    begin(call);
    expect(phase1(input), "rejected");

    return done();
}
