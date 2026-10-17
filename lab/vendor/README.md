# vendor/

marked 18.0.14, committed so that the lab pages work with no network. It
turns each exercise's `README.md` into the page that shows it.

| File | What it is |
|------|------------|
| `marked/marked.umd.js` | The parser. Loaded by a plain `<script>`; it defines `marked` |
| `marked/LICENSE` | Its MIT licence |

highlight.js is not here: the pages load the copy that comes inside the decks'
reveal.js plugin, `../../slides/vendor/reveal/plugin/highlight.js`, so a line
of NASM is coloured by the same grammar on a slide and on a lab page.

## Upgrading

```sh
curl -O https://registry.npmjs.org/marked/-/marked-<version>.tgz
tar xzf marked-<version>.tgz
cp package/lib/marked.umd.js package/LICENSE lab/vendor/marked/
```

Then update the version at the top of this file, and open an exercise page to
check it still renders.
