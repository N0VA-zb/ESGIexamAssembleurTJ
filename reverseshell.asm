global _start

section .text
_start:

mov rax, 0x29 ; syscall socket
