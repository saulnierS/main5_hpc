#ifndef __fonctionsCPU__H
#define __fonctionsCPU__H
#include <stdio.h> 
#include <stdlib.h>
//*****************************************************************************
//Fonctions CPU (trie de tableau)
//*****************************************************************************
void trie_a_bulle(int *tab,int size);
int verif_trie(int *tab,int size);
void fusion(int* tableau,int deb1,int fin1,int fin2);
void tri_fusion_bis(int* tableau,int deb,int fin);
void tri_fusion(int* tableau,int longueur);
void fusion_merde (int* a, int n, int m);
void tri_fusion_merde (int* liste, int taille);
void tri_fusion_solene(int *tab, int size);
void test(int *A,int *B);

#endif