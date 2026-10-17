# 01 · answer

Your first function returns 42.

```c
long answer(void);
```

A function hands its result back in `rax`. That's the whole exercise. What you
learn here is the loop you'll repeat in every other one: test, edit, test
again, and look inside with gdb when the test and you disagree.

The file is `lab/exercises/01-answer/answer.asm`. Open it in the editor.

## 1. Run the test

In the terminal, which opens in `lab/`:

```sh
./check 01
```

The function returns 0 for now, so the test says so:

```text
answer() ... expected 42, got 0
0 of 1 passed
```

## 2. Fix it

Change the line marked `TODO` so that it puts 42 in `rax`. Delete the
`TODO` comment while you're there: `./check` with no exercise lists everything,
and it calls a file with `TODO` still in it "not started". Then run the test
again.

<details>
<summary>Hint: the instruction</summary>

`mov rax, 0` already puts a number in `rax`. Only the number is wrong.

</details>

## 3. Look inside with gdb

```sh
./debug 01
```

gdb stops on the first instruction of `answer`. The top window shows the
registers, the middle one your source with the next line marked, and the
bottom one is where you type.

| Type | What it does |
|------|--------------|
| `si` | Run one instruction (*step instruction*). Watch `rax` change |
| `p $rax` | Print a register |
| `c` | Continue to the next time the test calls your function, or to the end |
| `q` | Quit |

Press Enter on an empty line to repeat the last command, which makes `si`
easy to run several times in a row.

## 4. Pick a tier

That's the whole workflow. Go back to the menu and pick any tier. They don't
depend on each other.

Running `./check` with no exercise lists every exercise and where you are with
each.
