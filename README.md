# main5_hpc
Projet : Batch merge and merge path sort

#Fichiers
code/: (contient l'ensemble des codes)

	code_seq.cu: (écrit en cuda) merge 2 tableaux en séquentiel sur cpu.

	mergeBatches_seq.cu: (écrit en cuda) trie un tableau à la manière de mergeBatches mais en séquentiel et sur CPU.

	mergeSmall_k.cu : (écrit en cuda) merge 2 tableaux sur gpu sur 1 seul block. La taille de A plus la taille de B ne doit pas dépasser 1024.

	mergeSmall_k_shared.cu : (écrit en cuda) merge 2 tableaux sur gpu sur 1 seul block. La taille de A plus la taille de B ne doit pas dépasser 1024. Cette fois on utilise la shared mémory du bloc.

	mergeBig_k.cu : (écrit en cuda) merge 2 tableaux sur gpu sur plusieurs blocks cette fois. Attention à ne pas dépasser la mémoire globale.

	sort.cu : (écrit en cuda) réalise le trie d'un tableau sur gpu avec plusieurs bloc et plusieurs threads.

	sort_stream.cu : (écrit en cuda) réalise le trie d'un tableau sur gpu avec plusieurs bloc et plusieurs threads et avec les streams.

	mergeSmallBatches_Only.cu : (écrit en cuda) divise un tableau en sous tableaux et merge des Batches de 1024 éléments maximums

	mergeBatches.cu : (écrit en cuda) divise un tableau en sous tableaux et merge les sous tableaux entre eux sous forme de Batches de 1024 en parallèle (avec les streams) dans un premier temps quand les tailles dépassent 1024 merge avec mergeBig_k. La shared et les streams sont mis à contribution

	cmd_mergeBatches.sh : permet d'executer mergeBatches pour differentes tailles et sauvegarde le tout dans un fichier .txt dans res/

	cmd_mergeSmall.sh  : permet d'executer mergeSmall_k et mergeSmall_k_shared pour differents nombres de threads et sauvegarde le tout dans des fichier .txt dans res/.

	cmd_sort.sh  : permet d'executer sort et sort_stream pour differentes tailles et sauvegarde le tout dans des fichier .txt dans res/.


	Makefile: la commande make permet d'executer tous les fichiers afin d'avoir tous les executables. Il y a un make clean disponible pour supprimer les exécutables et chaque question peut être compiler avec make question1 (cela peut être 1,2,3,5).attention il n'y a pas de code pour la question4

README.md : fichier guide

cmd.sh: permet d'executer l'ensemble des fichiers, contient toutes les commandes

Projet.pdf : sujet du projet

HPC_CODE.pdf : presentation des codes

HPC_RUNTIME.pdg : presentation des résultats des exécutions des codes

res/: contient l'ensemble des résultats d'exécution, et un fichier courbe.py permettant de tracer les courbes et de traiter les .txt.

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
Dès que vous créez un nouveau fichier ajoutez le au dépôt 
``git add fichier ``

Dès que vous modifiez un fichier un fichier ajoutez le au prochain
commit
``git add fichier ``

Commitez une version de votre travail 
``git commit -m "Un message" ``

A la fin de la séance votre projet doit étre mis dans le répo avec la commande
``git push``

Vérifiez que vous avez bien tout comité 
``git status``

pour revenir à la dernière version commit
``git checkout <fichier>``

Création d'une branche et basculement vers celle ci
``git checkout -b <nom>``

Vérification de la branche sur laquelle on est
``git branch -v``

basculement vers une branche existante
``git checkout <nom>``

push de la branche sur le server
``git push -u origin <nom>``
