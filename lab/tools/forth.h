/* forth.h - what tier E's four tests share: the way into the Forth, its
 * execution tokens, a way to write a number into a thread, and running one.
 *
 * Include it after check.h.
 */

/* The way in, in the exercise's .asm: runs the thread with the data stack
 * starting empty at stack, and returns DSP as BYE found it. */
long *forth(const void *const *thread, long *stack);

/* The execution tokens: the address of each word's code field. A thread is a
 * list of them, ended by BYE's. A test uses only the words its exercise's
 * file defines. */
extern const void *const xt_lit;
extern const void *const xt_bye;
extern const void *const xt_dup;
extern const void *const xt_swap;
extern const void *const xt_plus;
extern const void *const xt_dot;

/* A thread, written the way the tests write them:
 *
 *     THREAD(LIT, N(2), LIT, N(3), PLUS, BYE)
 *
 * is { &xt_lit, 2, &xt_lit, 3, &xt_plus, &xt_bye }: 2 3 + and back to C. */
#define THREAD(...) ((const void *[]) { __VA_ARGS__ })
#define N(n) ((const void *) (long) (n))
#define LIT &xt_lit
#define BYE &xt_bye
#define DUP &xt_dup
#define SWAP &xt_swap
#define PLUS &xt_plus
#define DOT &xt_dot

/* The data stack. It grows down, so the empty stack is its high end, and the
 * first item pushed goes in the cell below that. Four spare cells above the
 * empty end take the writes of a word that pops more than was pushed, so
 * that it shows up as a wrong answer rather than as damage to the test. */
static long stack[16 + 4];
#define EMPTY (stack + 16)

/* Run a thread on an empty data stack. Returns what it left there, bottom
 * item first, the way Forth's .s shows a stack: "2 3" has 3 on top. */
static const char *run(const void *const *thread)
{
    static char shown[256];
    long *dsp = forth(thread, EMPTY);

    if (dsp > EMPTY) {
        snprintf(shown, sizeof shown,
                 "DSP %ld cells above the empty stack: more popped than pushed",
                 (long) (dsp - EMPTY));
        return shown;
    }
    if (dsp < stack) {
        return "DSP past the stack's last cell: more than 16 items on it";
    }

    shown[0] = '\0';
    for (long *item = EMPTY - 1; item >= dsp; item--) {
        char number[24];
        const char *format = item == EMPTY - 1 ? "%ld" : " %ld";
        snprintf(number, sizeof number, format, *item);
        strcat(shown, number);
    }
    return shown;
}
