//*****************************************************************************
//Projet HPC fusion et trie de tableaux sur GPU
//Auteur: ROBIN Clement et SAULNIER Solene
//Promo: MAIN5
//Date: decembre 2020
//information code en sur cpu
//*****************************************************************************
#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#define N 536870912

//*****************************************************************************
//Fonctions CPU fusion et verification
//*****************************************************************************
int verif_trie(int *tab,int size)
{
    for (int i=0; i<size-1; i=i+1)
      if (tab[i]>tab[i+1])
          return i;
    return -1;
    
}

void fusion(int* tableau,int deb1,int fin1,int fin2)
{
  int *table1;
  int deb2=fin1+1;
  int compt1=deb1;
  int compt2=deb2;
  int i;
        
  table1=(int *) malloc((fin1-deb1+1)*sizeof(int));

  //on recopie les elements du debut du tableau
  for(i=deb1;i<=fin1;i++)
  {
      table1[i-deb1]=tableau[i];
  }
                  
  for(i=deb1;i<=fin2;i++)
  {        
    if (compt1==deb2) //c est que tous les elements du premier tableau ont ete utilises
    {
      break; //tous les elements ont donc ete classes
    }
    else if (compt2==(fin2+1)) //c est que tous les elements du second tableau ont ete utilises
    {
      tableau[i]=table1[compt1-deb1]; //on ajoute les elements restants du premier tableau
      compt1++;
    }
    else if (table1[compt1-deb1]<tableau[compt2])
    {
      tableau[i]=table1[compt1-deb1]; //on ajoute un element du premier tableau
      compt1++;
    }
    else
    {
      tableau[i]=tableau[compt2]; //on ajoute un element du second tableau
      compt2++;
    }
  }
  free(table1);
}
        

void tri_fusion_bis(int* tableau,int deb,int fin)
{
  if (deb!=fin)
  {
    int milieu=(fin+deb)/2;
    tri_fusion_bis(tableau,deb,milieu);
    tri_fusion_bis(tableau,milieu+1,fin);
    fusion(tableau,deb,milieu,fin);
  }
}

void tri_fusion(int* tableau,int longueur)
{
  if (longueur>0)
  {
    tri_fusion_bis(tableau,0,longueur-1);
  }
}

//*****************************************************************************
//Fonctions CPU (merge tableau)
//*****************************************************************************

void mergeSmall_k(int *A, int *B, int *M, int size_A, int size_B, int size_M)
{
  
  int i = 0;
  int j = 0;
  while (i+j<size_M)
  {  
    if (i>size_A)
    {
      M[i+j]=B[j];
      j++;
    }
    else
    {
      if (j>=size_B || A[i]<B[j])
      {
        M[i+j]=A[i];
        i++;
      }
      else
      {
        M[i+j]=B[j];
        j++;
      }
    }
  }
}


 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char *argv[]) 
{
  //srand (time (NULL));
  srand(42);

  /*Declaration des variables CPU*/
  /*Taille des tableaux*/
  int h_taille_A=1024/2;
  int h_taille_B=1024-h_taille_A;
  int h_taille_M=h_taille_A+h_taille_B;

  /*Traitement des options*/
  for (int i=0; i<argc-1; i=i+1)
  {
      if (strcmp(argv[i],"--sA")==0 && atoi(argv[i+1])<N )
          h_taille_A=atoi(argv[i+1]);
      if (strcmp(argv[i],"--sB")==0 && atoi(argv[i+1])<N)
          h_taille_B=atoi(argv[i+1]);   
  }


  if (h_taille_A < h_taille_B)
  {
    int tpm=h_taille_A;
    h_taille_A=h_taille_B;
    h_taille_B=tpm;
  }

  /*Tableaux et allocation memoire*/
  int *h_A;
  int *h_B;
  int *h_M;
  h_A=(int *)malloc(h_taille_A*sizeof(int));
  h_B=(int *)malloc(h_taille_B*sizeof(int));
  h_M=(int *)malloc(h_taille_M*sizeof(int));
  
   
  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_A;i++)
    h_A[i]=rand()%10000;
  
  for (int i=0; i<h_taille_B;i++)
    h_B[i]=rand()%10000;
  
  tri_fusion(h_A, h_taille_A);
  tri_fusion(h_B, h_taille_B);

  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  /*Merge tableau*/
  cudaEventRecord(start);
  mergeSmall_k(h_A, h_B, h_M, h_taille_A, h_taille_B, h_taille_M);
  cudaDeviceSynchronize();
  cudaEventRecord(stop);

  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"code sequentiel Taille_A: %d, Taille_B: %d, Taille_M: %d, Temps: %.5f, verif: %d\n", h_taille_A, h_taille_B, h_taille_M,ms,verif_trie(h_M,h_taille_M));
  
  
  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==-1)
    printf("\n ok tableau M trie\n");
  else
    printf("\n KO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));


  /*Liberation*/
  free(h_A);
  free(h_B);
  free(h_M);
 

    return 0;
} 