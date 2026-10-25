# E · Build a Forth

Read this before the exercises. It covers how the Forth in this tier works,
which the talk only showed a glimpse of.

By the end of E4, the thread for `2 3 + .` prints 5. Each exercise's file
holds the whole Forth so far, with the earlier exercises already done, so
you can start at any of them.

## A thread

A Forth word written in Forth is compiled to a *thread*: a list of the words
it runs, in order, one cell each. There is no outer interpreter in this tier
to compile one, so the test writes its threads by hand, in C:

```c
THREAD(LIT, N(2), LIT, N(3), PLUS, DOT, BYE)
```

That's `2 3 + .`. A number in a thread is two cells: LIT, and then the number
itself, which LIT pushes onto the data stack. BYE at the end goes back to C.
`lab/tools/forth.h` turns the line above into the array of cells it stands
for: `{ &xt_lit, 2, &xt_lit, 3, &xt_plus, &xt_dot, &xt_bye }`.

## Execution tokens and code fields

Each cell of a thread holds an *execution token*: the address of a word's
*code field*. The code field is one cell too, and it holds the address of
the word's machine code. Two steps from the thread to the code:

```text
  the thread           xt_plus               plus
  ┌──────────┐         ┌──────────┐          mov  rax, [DSP]
  │ &xt_plus ├───────► │   plus   ├────────► add  DSP, 8
  └──────────┘         └──────────┘          add  [DSP], rax
                       the code field        jmp  next
```

In the files, the code field is labelled `xt_plus` and the machine code
`plus`. mforth calls them `xt_plus` and `code_plus`.

Why not put the code's address in the thread directly? Because then every
word would have to be machine code. In a full Forth, a word written in Forth
has a code field too, and it holds the address of a routine that runs that
word's own thread. The thread that calls a word never needs to know which
kind it is. This tier has only machine-code words, but it keeps the second
step, so it works the way mforth does.

## The registers

| Register | Called | Holds |
|----------|--------|-------|
| `rbx` | `IP` | The address of the next cell of the thread to run |
| `r12` | `DSP` | The address of the top item on the data stack |
| `rax` | `W` | The execution token of the word being started |

The files give the registers these names with `%define`, so `mov W, [IP]`
is `mov rax, [rbx]`.

`rbx` and `r12` are callee-saved, so a word that calls `printf` gets IP and
DSP back unchanged. `W` is needed only for the moment it takes to start a
word. After that, every word is free to use `rax`.

## NEXT

NEXT starts the next word. Every word ends by jumping to it:

```x86asm
next:
        mov     W, [IP]                 ; the execution token IP points at
        add     IP, 8                   ; step past it, ready for next time
        jmp     [W]                     ; jump through the word's code field
```

The brackets in `jmp [W]` matter. `W` holds the address of the code field,
and the code field holds the address of the code. `jmp [W]` reads the code
field and jumps to what it holds. `jmp W` would jump to the code field
itself, which is data, not code.

mforth pastes these three instructions into the end of every word with a
macro called NEXT, in `include/mforth.inc`. Here every word jumps to one
shared copy instead. That costs a jump, and gives gdb one place to stop
between words.

## The data stack

The stack grows down, and `DSP` points at the top item. The item under the
top one is a cell higher, at `[DSP + 8]`.

| To | Write |
|----|-------|
| Push `rax` | `sub DSP, 8`, then `mov [DSP], rax` |
| Pop into `rax` | `mov rax, [DSP]`, then `add DSP, 8` |

A pop leaves the number in memory. It is just no longer on the stack, and the
next push writes over it.

The test shows a stack the way Forth's `.s` does: bottom item first, so in
`2 3` the 3 is on top.

## Stack comments

Each word's comment says what it does to the stack, before and after the
`--`:

| Comment | Means |
|---------|-------|
| `+ ( n1 n2 -- n3 )` | Takes two numbers, the top one n2, and leaves one |
| `DUP ( n -- n n )` | Takes one number and leaves two copies of it |
| `. ( n -- )` | Takes a number and leaves nothing |

## The way in and the way out

The test calls `forth(thread, stack)`. `forth` saves `rbx` and `r12`, which
the C that called it expects back, then sets IP to the thread and DSP to the
empty stack, and jumps to NEXT.

BYE is the last word of every thread. It puts back what `forth` saved and
returns DSP to the test, which reads the stack from there.

`forth` also leaves `rsp` a multiple of 16, and no word moves it. That is
what lets a word call `printf` without doing anything around the call. mforth
does the same, once, at the start of `main`.

## In gdb

| Type | What it shows |
|------|---------------|
| `b next` | Stop each time a word ends and the next one starts |
| `x/4a $rbx` | The next four cells of the thread, with execution tokens shown by name |
| `x/a $rax` | After `mov W, [IP]`: the code field, and the code it points at |
| `x/4gd $r12` | The top four items of the data stack, top first |
| `c` | Continue: to the next word, when you have `b next` |

`x/4gd` shows memory upward from `DSP`, so the top of the stack comes first,
the opposite of the order the test writes.
