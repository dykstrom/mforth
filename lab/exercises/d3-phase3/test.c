/* test.c - puzzle D3: does phase3 accept the input in phase3.asm? */
#include "../../tools/check.h"

int phase3(const char *input);
extern const char input[];

int main(void)
{
    char call[200];
    snprintf(call, sizeof call, "phase3(\"%s\")", input);

    begin(call);
    expect(phase3(input), "rejected");

    return done();
}
