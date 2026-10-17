/* test.c - exercise A6: upcase() changes a string in place. */
#include "../../tools/check.h"

void upcase(char *s);

/* Run upcase on a copy of text, which is a string constant and cannot be
 * written to, and compare the copy with the expected result. The copy has
 * a '#' one past its 0, which upcase must not reach. */
static void check(const char *text, const char *expected)
{
    char s[100];
    char call[200];

    strcpy(s, text);
    s[strlen(text) + 1] = '#';
    snprintf(call, sizeof call, "upcase(\"%s\")", text);

    begin(call);
    upcase(s);
    if (s[strlen(text) + 1] != '#') {
        expect(0, "changed the byte after the 0 that ends the string");
    } else {
        expect_string(s, expected);
    }
}

int main(void)
{
    check("hello", "HELLO");
    check("Hello, world!", "HELLO, WORLD!");
    check("ALREADY", "ALREADY");
    check("abc 123 xyz", "ABC 123 XYZ");

    /* The neighbours of the two ranges: '`' and '{' sit just either side
     * of a to z, '@' and '[' just either side of A to Z. None of them is a
     * letter, so none of them changes. */
    check("`az{", "`AZ{");
    check("@AZ[", "@AZ[");

    check("", "");

    return done();
}
