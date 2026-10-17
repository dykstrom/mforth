# D3 · phase 3

Find an input `phase3` accepts.

```c
int phase3(const char *input);
```

No source, one libc call, and a loop that looks each character of your
input up in a table. More than one answer works.

Your answer goes between the quotes in
`lab/exercises/d3-phase3/phase3.asm`.

```sh
./check d3
```

```sh
./debug d3
```

<details>
<summary>Hint 1: how long</summary>

The libc call is `strlen`, and the `cmp` straight after it says how long the
input has to be. Put in something of that length before you go on, or the
loop is never reached.

`x/30i phase3` shows the whole phase, past the labels.

</details>

<details>
<summary>Hint 2: the loop</summary>

`rbx` holds your input and `rcx` counts. Each time round the loop:

- `movzx eax, BYTE PTR [rbx+rcx*1]` loads one character of your input.
- `and eax, 0xf` keeps its low four bits: a number from 0 to 15.
- The next `movzx` uses that number as an index into a table.
- The `cmp` checks the byte it found against byte `rcx` of another string.

Both the table and the other string are at addresses in those two
instructions. `x/s` them.

</details>

<details>
<summary>Hint 3: from the word back to the input</summary>

The loop has to find the other string's letters, in order. For each one,
count from 0 along the table to where it is. That gives five numbers from 0
to 15, and each character of your input has to have one of them as its low
four bits.

</details>

<details>
<summary>Hint 4: characters with given low bits</summary>

In ASCII, `a` is `0x61`, `b` is `0x62`, and so on up to `o` at `0x6f`. So
the low four bits of `a` to `o` are 1 to 15. A character whose low four bits
are 7 is `g`.

</details>

## When it passes

Find a second answer that looks nothing like your first, and check that it
passes too. ASCII comes in rows of sixteen: `0x40` to `0x4f` is `@` and
`A` to `O`, and `0x30` to `0x3f` is the digits and six punctuation marks.
How many different answers are there?
