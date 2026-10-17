# A4 · strlen

Return the length of a string.

```c
size_t strlen(const char *s);
```

| What | Where it is |
|------|-------------|
| `s`, the address of the first character | `rdi` |
| The length you return | `rax` |

A C string is one byte per character, and it ends at the first byte that's
0. That byte isn't counted: `"hello"` is five bytes long, plus the 0.

The file is `lab/exercises/a4-strlen/strlen.asm`.

```sh
./check a4
```

```sh
./debug a4
```

## One byte at a time

`[rdi]` names memory, but not how much of it. With a register on the other
side, the register says: `rax` is eight bytes, `al` one. With a number on
the other side, nothing does, and nasm wants to be told:

```x86asm
        cmp     byte [rdi], 0           ; compare one byte with 0
        cmp     qword [rdi], 0          ; compare eight bytes with 0
```

<details>
<summary>Hint 1: reaching byte i</summary>

Byte `i` of the string is at `rdi + i`, and x86-64 can say that in one
operand: `[rdi + rax]`. If the count you're keeping is in `rax`, it's also
how far along the string you've got.

</details>

<details>
<summary>Hint 2: the shape of it</summary>

```x86asm
strlen:
        xor     eax, eax                ; count = 0
.next:
        ; if the byte at rdi + rax is 0, jump to .done
        ; count one more, and go round again
.done:
        ret
```

</details>

<details>
<summary>Hint 3: an empty string</summary>

`""` is one byte, the 0. Look at the byte before counting it, not after,
and the empty string comes out as 0 without a case of its own.

</details>

## When it passes

Run `./debug a4` and continue with `c` to the case `strlen("Hello, world!")`.
Type `x/s $rdi` to see the string in memory, and `x/14xb $rdi` to see the
same fourteen bytes as numbers: `x` for hex, `b` for bytes. The last one is
the 0, and the one before it is `0x21`, the `!`.
