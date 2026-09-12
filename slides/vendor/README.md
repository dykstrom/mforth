# vendor/

reveal.js 6.0.2, committed so that a deck opens with no network.

Only the files a deck loads are here. The `reveal/` directory keeps the
layout of the package's own `dist/`, so paths in a deck match what the
reveal.js documentation shows.

| File | What it is |
|------|------------|
| `reveal/reset.css` | The CSS reset reveal.js expects |
| `reveal/reveal.css` | reveal.js itself |
| `reveal/reveal.js` | The presentation engine |
| `reveal/theme/black.css` | The base theme. `../theme/mforth.css` loads after it and overrides it |
| `reveal/plugin/highlight.js` | Syntax highlighting. Carries all of highlight.js, so `x86asm` and `armasm` work with no extra file |
| `reveal/plugin/highlight/monokai.css` | The colours the highlighter uses |
| `reveal/plugin/notes.js` | The speaker view: notes, next slide, timer |

## Upgrading

Download the tarball and copy the seven files out of its `dist/` directory:

```sh
curl -O https://registry.npmjs.org/reveal.js/-/reveal.js-<version>.tgz
tar xzf reveal.js-<version>.tgz
cp package/dist/{reset.css,reveal.css,reveal.js} slides/vendor/reveal/
cp package/dist/theme/black.css slides/vendor/reveal/theme/
cp package/dist/plugin/{highlight.js,notes.js} slides/vendor/reveal/plugin/
cp package/dist/plugin/highlight/monokai.css slides/vendor/reveal/plugin/highlight/
```

Then update the version at the top of this file, and open a deck to check it
still works. The `.mjs` copies, the other themes and the TypeScript
declarations in the tarball are not used.
