BITS 64
default rel

section .data
    msg db "parcer: alive", 10
    msg_len equ $ - msg
    msg_usage db "Usage: ./parcer <elf>", 10
    msg_usage_len equ $ - msg_usage

section .bss
    fd: resq 1 ; on réserve 8 octets pour stocker le file descriptor

section .text
    global _start

_start:
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl .usage
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, msg_len
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

.usage:
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_usage]
    mov rdx, msg_usage_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall