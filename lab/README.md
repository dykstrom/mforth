# lab/

A self-paced x86-64 assembly lab. Attendees start with tier 0, then pick any
tier in any order. Every exercise is one function to write in NASM, a test
that calls it, and a page with hints and a solution behind a button. Tier D
turns that round: the function is given, without source, and the attendee
finds the input it accepts.

## Running it in Codespaces

On the repository's GitHub page: **Code → Codespaces → Create codespace on
\<branch\>**. The first start builds the image, which takes a few minutes.
After that:

- The lab pages open in a browser tab of their own. If they don't, open the
  **Ports** tab in VS Code and click the globe next to "Lab pages".
- The terminal opens in `lab/`, where every command on the pages runs.

## Running it on your own machine

You need Docker. Then, from the repository root:

```sh
lab/docker-shell
```

That builds the image (once) and leaves you in a shell in `lab/`, with the
pages at <http://localhost:8000/lab/>. Edit the files with any editor on your
machine.

On an Apple Silicon Mac, Docker has to run x86-64 programs through Rosetta,
or `./debug` cannot read the registers. See the comment at the top of
`docker-shell`.

## Commands

| Command | What it does |
|---------|--------------|
| `./check` | One line for every exercise: PASS, FAIL, not started, and so on |
| `./check c2` | Build C2 and show every case its test ran |
| `./debug c2` | Run C2's test under gdb, stopped at the start of your function |
| `./check --solutions` | Build every exercise from its `solution.asm`. Run it before a session: every line should say PASS |

## Layout

| Path | What is there |
|------|---------------|
| `index.html` | The menu |
| `page.html` | One exercise (`?ex=c2`) or one tier's notes (`?tier=C`) |
| `lab.js`, `lab.css` | What both pages share |
| `exercises.json` | Every tier and exercise, in menu order. An exercise without a `dir` is planned and shows greyed out |
| `exercises/<id>-<name>/` | One exercise. See below |
| `tiers/` | A tier's notes, for what the tier needs that the talk doesn't cover |
| `puzzle/` | Tier D's puzzle. Reading it gives the answers away. See `puzzle/README.md` |
| `check`, `debug` | The two commands |
| `docker-shell` | Runs the lab outside Codespaces |
| `tools/` | What `check` and `debug` share: the build, the C side of the tests, gdb's settings, and the register list for gdb under Rosetta. Also `forth.h`, what tier E's tests share, and `serve.py`, the pages' web server, which sends `/` on to `/lab/` |
| `vendor/` | marked, which renders the Markdown. See `vendor/README.md` |

The pages load highlight.js and the x86 grammar fix from `../slides/`, so they
have to be served from the repository root, not from `lab/`. They don't work
opened as a `file://` path, because they fetch the files they show.

## An exercise

`exercises/c2-average/` holds:

| File | What it is |
|------|------------|
| `README.md` | The page: the task, the commands, hints in `<details>` blocks |
| `average.asm` | What the attendee edits. Named after the function it defines, which is how `check` and `debug` find the function. Has a `TODO` until it's started |
| `solution.asm` | A commented solution. The page fetches it when the button is pressed |
| `test.c` | Calls the function once per case, using `tools/check.h` |

To add one: make the directory, add an entry with a `dir` to
`exercises.json`, and run `./check --solutions`.

A function that prints would print into the middle of the test's own lines.
So a test whose function calls `puts` or `printf` defines its own function of
that name, which the attendee's `call` reaches instead of libc's. It keeps the
text for the test to compare and checks that the stack was 16-byte aligned at
the call. `tools/check.h` has the pieces, and prints with `fprintf` so that its
own lines don't land there too.

A tier D exercise holds `phase1.asm` and the rest as above, but `phase1.asm`
is the attendee's answer, a string, and the function that judges it is
`puzzle/phase1.asm`. `tools/build.sh` links that file in, without `-g`, so gdb
has only the machine code to show.

## gdb on Apple Silicon

Under Rosetta, gdb cannot read a program's registers the usual way, so
`./debug` starts the test with `ROSETTA_DEBUGSERVER_PORT` set and connects to
Rosetta's own gdb server instead. That server doesn't say which registers it
has, and gdb's default list includes two it can't supply, so `debug` gives gdb
the list in `tools/rosetta-registers.xml`. Without it the register window
stays empty. In Codespaces, and on any x86-64 machine, gdb runs the test
directly.
