/* test.c - exercise A4: strlen() of a string.
 *
 * strlen is declared in string.h, which check.h includes. The definition
 * the program gets is the attendee's: the linker finds it in the program
 * before it looks in libc. */
#include "../../tools/check.h"

int main(void)
{
    begin("strlen(\"hello\")");
    expect_long(strlen("hello"), 5);

    begin("strlen(\"\")");
    expect_long(strlen(""), 0);

    begin("strlen(\"a\")");
    expect_long(strlen("a"), 1);

    begin("strlen(\"Hello, world!\")");
    expect_long(strlen("Hello, world!"), 13);

    /* The count stops at the first 0, not at the end of the array. */
    begin("strlen(\"abc\\0def\")");
    expect_long(strlen("abc\0def"), 3);

    char long_one[1001];
    for (int i = 0; i < 1000; i++) {
        long_one[i] = 'x';
    }
    long_one[1000] = '\0';
    begin("strlen(\"xxx...x\"), 1000 of them");
    expect_long(strlen(long_one), 1000);

    return done();
}
