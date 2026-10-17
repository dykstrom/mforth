/* test.c - exercise B1: hello() prints "Hello, world!" with puts. */
#include "../../tools/check.h"

void hello(void);

static int calls;

/* hello's "call puts" arrives here instead of at libc's puts. See "Catching
 * output" in check.h. */
int puts(const char *s)
{
    calls++;
    catch_alignment(CALLED_ALIGNED());
    catch_text(s);
    catch_text("\n");
    return 1;
}

int main(void)
{
    catch_reset();
    begin("hello()");
    hello();
    expect_string(caught, "Hello, world!\n");

    begin("rsp at call puts");
    if (calls == 0) {
        expect(0, "puts was never called");
    } else {
        expect(misaligned_calls == 0,
               "8 bytes off a multiple of 16: the 16-byte rule in the tier notes");
    }

    return done();
}
