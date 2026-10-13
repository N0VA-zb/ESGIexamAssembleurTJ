BITS 64
default rel

section .data
    msg db "parcer: alive", 10
    msg_len equ $ - msg

section .text
    global _start

_start:
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, msg_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall