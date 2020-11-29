# main5_hpc
Projet : Batch merge and merge path sort

#Fichiers
fonctionsCPU.c : (écrit en c) fonctions sur CPU pour le trie et la verification du trie des tableaux. Il y a des fonctions tests egalement.

question1_mergeSmall_k.cu : (écrit en cuda) merge 2 tableaux sur 1 seul bloc. La taille de A plus la taille de B ne doit pas dépasser le nombre de threads d'un bloc.

question1_mergeSmall_k_shared.cu : (écrit en cuda) merge 2 tableaux sur 1 seul bloc. La taille de A plus la taille de B ne doit pas dépasser le nombre de threads d'un bloc. Cette fois on utilise la shared mémory du bloc

question2_mergeBig_k.cu : (écrit en cuda) merge 2 tableaux sur plusieurs bloc cette fois. Attention à ne pas dépasser la mémoire globale.

question3_sort.cu : (écrit en cuda) réalise le trie d'un tableau sur gpu avec plusieurs bloc et plusieurs threads.

question4_mergeBig_k.cu : (écrit en cuda) merge dans un premier temps les sous tableaux de A et B puis merge 2 à 2 les tableaux pour en obtenir un seul.

question4_mergeBig_k_stream.cu : (écrit en cuda) merge dans un premier temps les sous tableaux de A et B puis merge 2 à 2 les tableaux pour en obtenir un seul. Cette fois on utilise des streams pour paralléliser aussi les kernels

question5_mergeSmallBatch_shared.cu (écrit en cuda) merge dans un premier temps les sous tableaux de A et B puis merge 2 à 2 les tableaux pour en obtenir un seul. Cette version utilise la shared memory et la taille de chacun des sous tableaux de A et B doit être inférieur aux nombres de threads par bloc. 

question5_treeMergePerBlock_simpleExemple.cu : (écrit en cuda) merge dans un premier temps les sous tableaux de A et B puis merge 2 à 2 les tableaux pour en obtenir un seul. Cette version utilise la shared memory et la taille de chacun des sous tableaux de A et B doit être inférieur aux nombres de threads par bloc.  [?]

question5_smallBatchesOnly.cu : (écrit en cuda) merge dans un premier temps les sous tableaux de A et B puis merge 2 à 2 les tableaux pour en obtenir un seul. Cette version utilise la shared memory et la taille de chacun des sous tableaux de A et B doit être inférieur aux nombres de threads par bloc.  [?]

cmd.sh: permet d'executer l'ensemble des fichiers, contient toutes les commandes. attention rectifier les droits pour pouvoir l'executer. (./cmd.sh)

Makefile: la commande make permet d'executer tous les fichiers afin d'avoir tous les executables. 

README.md : fichier guide

#Execution
Ce projet est codé en c et en cuda. Il est implémenté pour s'executer sur GPU. Avant d'executer n'importe quel fichier cuda il faut faire (gcc -o fonctionsCPU.o -c fonctionsCPU.c). Autrement il suffit de compiler avec nvcc les fichiers cuda (nvcc -o nom_fichier nom_fichier.cu). puis d'executer (./nom_fichier)

# Commande git
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
