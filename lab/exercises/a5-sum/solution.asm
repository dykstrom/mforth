; solution.asm - exercise A5: the sum of n numbers.
;
;     long sum(const long *a, long n);

        global  sum

        section .text
sum:
        xor     eax, eax                ; total = 0

        ; Nothing to add up: the 0 is the answer. Going round the loop once
        ; anyway would read a number that isn't in the array.
        test    rsi, rsi
        jz      .done

        ; Element i lives at rdi + i*8: eight bytes to a long. add can read
        ; its second operand straight from memory, so the loop needs no
        ; register to hold the element in.
        xor     ecx, ecx                ; i = 0
.next:
        add     rax, [rdi + rcx*8]      ; total += a[i]
        inc     rcx
        cmp     rcx, rsi
        jl      .next                   ; while i < n
.done:
        ret
