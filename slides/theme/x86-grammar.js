/* Two corrections to highlight.js's x86 assembly grammar.
 *
 * Reveal calls this from beforeHighlight, before anything is coloured. The
 * vendored plugin stays as it was downloaded.
 *
 * 1. A label after a blank line loses its colour.
 *
 * The grammar finds a label with the rule "start of a line, any whitespace, a
 * name, a colon". Its whitespace class includes the newline, so where a blank
 * line comes first the rule matches from the blank line instead of from the
 * label, and that label is left uncoloured:
 *
 *     section .rodata
 *                                 <- a blank line
 *     msg:    db      "hello", 0  <- msg: stays white
 *     count:  dq      0           <- count: is coloured
 *
 * Two labels that are the same kind of thing then look different, and nothing
 * reports it. Allowing only spaces and tabs where the rule starts fixes it,
 * which is what the arm64 grammar next door already does.
 *
 * 2. %macro and %endmacro are missing.
 *
 * The list of NASM directives the grammar knows has %define, %include, even
 * %ifmacro - but not %macro or %endmacro, so the two lines that open and
 * close every macro in this repo are the only ones in the block with no
 * colour. Adding them to the same list is the whole fix.
 */
function fixX86Grammar(hljs) {
    const language = hljs.getLanguage('x86asm');
    if (!language) return;              // no x86 grammar loaded

    const symbol = language.contains.find(mode => mode.className === 'symbol');
    if (symbol && symbol.variants) {
        for (const variant of symbol.variants) {
            if (typeof variant.begin === 'string') {
                variant.begin = variant.begin.replace(/^\^\\s\*/, '^[ \\t]*');
            }
        }
    }

    // Still a space-separated string at this point: highlight.js turns the
    // keyword lists into its own tables the first time it colours something,
    // and that has not happened yet.
    const meta = language.keywords && language.keywords.meta;
    if (typeof meta === 'string' && !meta.split(' ').includes('%macro')) {
        language.keywords.meta = meta + ' %macro %endmacro';
    }
}
