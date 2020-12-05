# main5_hpc
Projet : Batch merge and merge path sort

#Fichiers
code/: (contient l'ensemble des codes)
time_register/: (permet d'enregistrer les temps d'execution des codes)
 => ces repertoires contiennent les mêmes fichiers qui sont les suivants:

code_seq.cu: (écrit en cuda) merge 2 tableaux en séquentiel sur cpu.

mergeSmall_k.cu : (écrit en cuda) merge 2 tableaux sur gpu sur 1 seul block. La taille de A plus la taille de B ne doit pas dépasser 1024.

mergeSmall_k_shared.cu : (écrit en cuda) merge 2 tableaux sur gpu sur 1 seul block. La taille de A plus la taille de B ne doit pas dépasser 1024. Cette fois on utilise la shared mémory du bloc.

mergeBig_k.cu : (écrit en cuda) merge 2 tableaux sur gpu sur plusieurs blocks cette fois. Attention à ne pas dépasser la mémoire globale.

sort.cu : (écrit en cuda) réalise le trie d'un tableau sur gpu avec plusieurs bloc et plusieurs threads.

sort_stream.cu : (écrit en cuda) réalise le trie d'un tableau sur gpu avec plusieurs bloc et plusieurs threads et avec les streams.

mergeSmallBatches_Only.cu : (écrit en cuda) divise un tableau en sous tableaux et merge des Batches de 1024 éléments maximums

mergeBatches.cu : (écrit en cuda) divise un tableau en sous tableaux et merge les sous tableaux entre eux sous forme de Batches de 1024 en parallèle (avec les streams) dans un premier temps quand les tailles dépassent 1024 merge avec mergeBig_k. La shared et les streams sont mis à contribution


cmd.sh: permet d'executer l'ensemble des fichiers, contient toutes les commandes. attention rectifier les droits pour pouvoir l'executer. Faire chmod 777 cmd.sh puis ./cmd.sh

Makefile: la commande make permet d'executer tous les fichiers afin d'avoir tous les executables. Il y a un make clean disponible pour supprimer les exécutables et chaque question peut être compiler avec make question1 (cela peut être 1,2,3,5).attention il n'y a pas de code pour la question4

README.md : fichier guide

#Execution
Ce projet est codé en c et en cuda. Il est implémenté pour s'executer sur GPU. Autrement il suffit de compiler avec nvcc les fichiers cuda (nvcc -o nom_fichier nom_fichier.cu). puis d'executer (./nom_fichier)

Un makefile est diponible:
Compilation de tous les fichiers
``make ``
Compilation de la question1
``make question1 ``
Compilation de la question2
``make question2 ``
Compilation de la question3
``make question3 ``
Compilation de la question5
``make question5 ``
Compilation du code en séquentiel
``make sed ``

Un cmd.sh est diponible:
``chmod 777 cmd.sh ``
``./cmd.sh ``

# Rappel Commande git
Dès que vous créez un nouveau fichier ajouter le au dépôt 
``git add fichier ``

Dès que vous modifier un fichier un fichier ajouter le au prochain
commit
``git add fichier ``

Commiter une version de votre travail 
``git commit -m "Un message" ``

A la fin de la séance votre projet doit étre mis dans le répo avec la commande
``git push``

Vérifier que vous avez bien tout comité 
``git status``

revenir à la dernière version commit
``git checkout <fichier>``

Création d'une branche et basculement vers celle ci
``git checkout -b <nom>``

Vérification de la branche sur laquelle on est
``git branch -v``

basculement vers une branche existante
``git checkout <nom>``

push de la branche sur le server
``git push -u origin <nom>``
