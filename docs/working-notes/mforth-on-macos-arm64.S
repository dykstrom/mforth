// Sketch: what mforth would look like on macOS/arm64.

#define IP  x19
#define DSP x20
#define RSP x21
#define W   x9

.macro NEXT
    ldr     W, [IP], #8             // fetch the token, step IP past it
    ldr     x10, [W]                // the word's code field
    br      x10                     // and into its machine code
.endm

    .text
    .globl  _main
    .p2align 2
_main:
    adrp    x0, banner@PAGE
    add     x0, x0, banner@PAGEOFF
    bl      _puts

    adrp    DSP, _data_stack@PAGE
    add     DSP, DSP, _data_stack@PAGEOFF
    add     DSP, DSP, #16, lsl #12          // top of a 64 KB region
    adrp    RSP, _return_stack@PAGE
    add     RSP, RSP, _return_stack@PAGEOFF
    add     RSP, RSP, #16, lsl #12

    adrp    IP, thread@PAGE
    add     IP, IP, thread@PAGEOFF
    NEXT

docol:
    str     IP, [RSP, #-8]!         // push IP: one instruction
    add     IP, W, #8
    NEXT

code_exit:
    ldr     IP, [RSP], #8           // pop IP: one instruction
    NEXT

code_lit:
    ldr     x10, [IP], #8
    str     x10, [DSP, #-8]!
    NEXT

code_dot:
    ldr     x1, [DSP], #8
    sub     sp, sp, #16             // Apple arm64: variadic args go on the stack
    str     x1, [sp]
    adrp    x0, dot_format@PAGE
    add     x0, x0, dot_format@PAGEOFF
    bl      _printf
    add     sp, sp, #16
    NEXT

code_cr:
    mov     w0, #10
    bl      _putchar
    NEXT

code_bye:
    mov     w0, #0
    bl      _exit

    .data
    .p2align 3
xt_exit:    .quad code_exit
xt_lit:     .quad code_lit
xt_dot:     .quad code_dot
xt_cr:      .quad code_cr
xt_bye:     .quad code_bye

xt_print42:
    .quad   docol
    .quad   xt_lit, 42
    .quad   xt_dot
    .quad   xt_cr
    .quad   xt_exit

thread:
    .quad   xt_print42
    .quad   xt_print42
    .quad   xt_bye

    .section __TEXT,__cstring
banner:     .asciz "mforth 0.1.0"
dot_format: .asciz "%ld "

.zerofill __DATA,__bss,_data_stack,65536,4
.zerofill __DATA,__bss,_return_stack,65536,4
