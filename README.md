- Projet Assembleur — ELF Infector

L'objectif est d'infecter un binaire ELF shellcode qui s'exécute au lancement du programme.

l'arborescence : 

ESGIexamAssembleurTJ/
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