global _start

section .text
_start:

mov rax, 0x29 ; syscall socket
mov rdi, 2    ; inet en IPv4
mov rsi, 1    ; sock stream pour tcp
mov rdx, 0    ; protocol = 0 le noyau chosiit auto tcp
syscall

mov r12, rax  ; sauvegarde dans r12 pour eviter l'ecrasement des autres syscall 

