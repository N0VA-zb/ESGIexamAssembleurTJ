BITS 64
default rel

section .data

    msg_usage db "Usage: ./parcer <elf>", 10    ; message affiché si mauvais nombre d'arguments
    msg_usage_len equ $ - msg_usage             ; $ = adresse courante, donc len = fin - début
    hexdigits db "0123456789abcdef"             ; pour convertir un hex en caractère


section .bss

    fd:     resq 1                  ; on réserve 8 octets pour stocker le file descriptor
    fsize:  resq 1                  ; taille du fichier
    buf:    resq 1                  ; adresse de la mmap

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl .usage                       ; si argc < 2 ,pas assez d'arguments

    ;open
    mov rdi, [rsp + 16]             ; rdi = argv[1] , chemin du fichier ELF à parser
    xor rsi, rsi                    ; rsi = 0 (O_RDONLY)
    mov rax, 2                      ; syscall ouvert
    syscall

    test rax, rax                   ; teste rax (met à jour les flags dont SF)
    jl .usage

    mov [fd], rax                   ; sauvegarde le fd dans rax

    ;lseek
    mov rdi, [fd]                   ; rdi = fd du fichier           
    xor rsi, rsi                    ; rsi = 0 (offset 0)
    mov rdx, 2                      ; SEEK_END
    mov rax, 8                      ; syscall lseek
    syscall
    mov [fsize], rax                ; rax = taille du fichier

    ;partie mmap
    xor rdi, rdi                    ; addr NULL
    mov rsi, [fsize]                ; longueur du fichier
    mov rdx, 3                      ; PROT_READ et WRITE / 1 pour lecture seule
    mov r10, 2                      ; r10 = MAP_PRIVATE (modifications non partagées)
    mov r8, [fd]                    ; r8 = fd du fichier
    xor r9, r9                      ; r9 = 0 (offset dans le fichier)
    mov rax, 9                      ; syscall mmap
    syscall

    mov [buf], rax


    ;exit
    mov rax, 60                     ; syscall exit
    xor rdi, rdi                    ; rdi = 0 (code de retour 0 succès)
    syscall

.usage:
    mov rax, 1                      ; rax = 1 (write)
    mov rdi, 1                      ; rdi = 1 (stdout)
    lea rsi, [msg_usage]            ; rsi (adresse du message d'usage)
    mov rdx, msg_usage_len
    syscall

    mov rax, 60
    mov rdi, 1
    syscall

    ; print_hex affiche rax en hexa
    print_hex:  
    push rbx    ;
    push rcx    ;
    push rdx    ; sauvegarde les registres qu'on va modifier
    push rsi    ;
    sub rsp, 16     ; 16 octets réservés pour le bugger
    lea rdi, [rsp + 15]
    mov byte [rdi], 0
    mov rcx, 16     ; compteur de 16 chiffres
.loop:
    dec rdi
    mov rbx, rax
    and rbx, 0xF
    lea rsi, [hexdigits]
    mov bl, [rsi + rbx]
    mov [rdi], bl
    shr rax, 4
    dec rcx
    jnz .loop
    lea rsi, [rsp]  ;
    mov rdx, 16     ;
    mov rax, 1      ; on affiche les 16 caractères du buffer
    mov rdi, 1      ;
    syscall         ;
    add rsp, 16
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret