BITS 64
default rel

section .data
    msg db "parcer: alive", 10
    msg_len equ $ - msg

section .bss
    fd: resq 1 ; on réserve 8 octets pour stocker le file descriptor

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, msg_len
    syscall

    mov rax, 60
    xor rdi, rdi    ; j'ai changé cette partie car ca avait fait un bug ( on restait en = 1 alors qu'on doit etre à 0)
    syscall