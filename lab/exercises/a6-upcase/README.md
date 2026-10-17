# A6 · uppercase in place

Change every lowercase letter in a string into a capital.

```c
void upcase(char *s);
```

| What | Where it is |
|------|-------------|
| `s`, the address of the first character | `rdi` |

Nothing is returned. The string is changed where it lies, one byte at a
time: `a` to `z` become `A` to `Z`, and every other byte stays as it is. The
string ends at the first byte that's 0.

The file is `lab/exercises/a6-upcase/upcase.asm`.

```sh
./check a6
```

```sh
./debug a6
```

## Characters are numbers

In ASCII, `'A'` is 65 and `'a'` is 97. Every capital is exactly 32 below its
lowercase letter. nasm turns a character in quotes into its number, so
`cmp al, 'a'` and `cmp al, 97` are the same instruction.

## Bytes in and out

`movzx eax, byte [rdi]` reads one byte and fills the rest of `eax` with
zeros: *move with zero extend*. Writing `eax` clears the top half of `rax` as
well, so after it `rax` holds just that one character.

`al` is the bottom byte of `rax`. Use it to compare one character, and to
write one back: `mov [rdi], al` stores one byte, because `al` is one byte.

<details>
<summary>Hint 1: is it a lowercase letter?</summary>

Two comparisons: below `'a'` it isn't one, and above `'z'` it isn't one
either. A character is never negative, so the unsigned jumps fit: `jb` for
*below*, `ja` for *above*.

</details>

<details>
<summary>Hint 2: walking the string</summary>

There's no length to count to. Move `rdi` along one byte at a time with
`inc rdi`, and stop when the byte it points at is 0. Check for the 0 before
changing anything.

</details>

<details>
<summary>Hint 3: the shape of it</summary>

```x86asm
upcase:
.next:
        movzx   eax, byte [rdi]         ; the character
        ; if it's 0, jump to .done
        ; if it's below 'a' or above 'z', jump to .skip
        ; take 32 off, and write the byte back
.skip:
        inc     rdi
        jmp     .next
.done:
        ret
```

</details>

## When it passes

Run `./debug a6` and continue with `c` to the case `upcase("Hello, world!")`.
`rdi` moves along the string as your code runs, so keep its first value
before it does:

```text
set $s = $rdi
display/s $s
```

`$s` is a name gdb keeps for you, and `display` shows the string at it again
after every command. Step with `si` and watch the letters change one at a
time.
