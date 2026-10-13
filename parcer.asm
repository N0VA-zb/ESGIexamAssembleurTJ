BITS 64
default rel

section .data
    msg db "parcer: alive", 10
    msg_len equ $ - msg
    msg_usage db "Usage: ./parcer <elf>", 10
    msg_usage_len equ $ - msg_usage
    hexdigits db "0123456789abcdef" ; pour convertir un hex en caractère
    msg_entry db "Entry point : 0x"
    msg_entry_len equ $ - msg_entry ; longueur calculeé automatiquement

section .bss
    fd: resq 1 ; on réserve 8 octets pour stocker le file descriptor
    fsize: resq 1   ; taille du fichier
    buf: resq 1

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jl .usage

    ;open
    mov rdi, [rsp + 16]
    xor rsi, rsi
    mov rax, 2  ; syscall ouvert
    syscall
    test rax, rax
    jl .usage
    mov [fd], rax

    ;lseek
    mov rdi, [fd]
    xor rsi, rsi
    mov rdx, 2      ; SEEK_END
    mov rax, 8       ; syscall lseek
    syscall
    mov [fsize], rax    ; rax = taille du fichier

    ;partie mmap
    xor rdi, rdi            ; addr NULL
    mov rsi, [fsize]        ; longuer du fichier
    mov rdx, 3              ; PROT_READ et WRITE
    mov r10, 2
    mov r8, [fd]
    xor r9, r9
    mov rax, 9              ; mmap
    syscall
    mov [buf], rax

    ;write
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg]
    mov rdx, msg_len
    syscall

    ;exit
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

    ;print_hex
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