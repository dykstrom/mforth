/* test.c - puzzle D2: does phase2 accept the input in phase2.asm? */
#include "../../tools/check.h"

int phase2(const char *input);
extern const char input[];

int main(void)
{
    char call[200];
    snprintf(call, sizeof call, "phase2(\"%s\")", input);

    begin(call);
    expect(phase2(input), "rejected");

    return done();
}
