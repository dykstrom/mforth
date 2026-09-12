/* A highlight.js grammar for Forth.
 *
 * highlight.js ships grammars for x86asm and armasm but none for Forth, so
 * the decks bring their own. A deck registers it inside Reveal.initialize:
 *
 *     highlight: { beforeHighlight: hljs => hljs.registerLanguage('forth', forthLanguage) }
 *
 * and then marks a block with class="language-forth".
 *
 * The whole grammar rests on one fact about Forth: a word is whatever sits
 * between two spaces. That is why $pattern is /\S+/ - highlight.js splits on
 * whitespace, exactly as Forth's own WORD does, so ":", "+" and ">R" are
 * words it can match like any other.
 */
const forthLanguage = hljs => ({
    name: 'Forth',
    case_insensitive: true,
    keywords: {
        $pattern: /\S+/,
        // The words mforth defines in src/*.asm and lib/prelude.f.
        keyword:
            ': ; immediate create variable constant does> ' +
            'if else then begin until while repeat do loop i ' +
            'branch 0branch (do) (loop) lit ' +
            'here allot , c, state execute find word number interpret ' +
            "['] >r r> r@ @ ! c@ c! " +
            'dup drop swap over rot depth ?dup nip tuck ' +
            '+ - * / mod /mod negate abs 1+ 1- 2* ' +
            '= < > 0= 0< and or xor invert ' +
            '. cr emit type space .s words key bye',
    },
    contains: [
        // A backslash comments out the rest of the line - but only when a
        // space follows it, because "\" is itself a word. Every begin regex
        // below looks at the surrounding spaces without consuming them: a
        // match that swallowed the newline would put two lines in one span,
        // and data-line-numbers counts lines by splitting on the newline.
        hljs.COMMENT(/\\(?=\s|$)/, /$/),
        // ( ... ) is the stack-effect comment. Same rule: "(" needs a space.
        hljs.COMMENT(/\((?=\s)/, /\)/),
        // ." prints the text up to the closing quote.
        {
            className: 'string',
            begin: /\."(?=\s)/,
            end: /"/,
        },
        // The name a colon definition gives the new word.
        {
            className: 'title.function',
            begin: /(?<=^|\s):\s+/,
            end: /\s/,
            excludeBegin: true,
            excludeEnd: true,
        },
        {
            className: 'number',
            begin: /(?<=^|\s)-?\d+(?=\s|$)/,
        },
    ],
});
