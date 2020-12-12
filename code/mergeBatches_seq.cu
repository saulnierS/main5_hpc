//*****************************************************************************
//Projet HPC fusion et trie de tableaux sur GPU
//Auteur: ROBIN Clement et SAULNIER Solene
//Promo: MAIN5
//Date: decembre 2020
//Question 5 en sequentiel
//*****************************************************************************

#include <stdio.h> 
#include <stdlib.h>
#define N 536870912
#define threadsPerBlock 1024
#define numBlocks 65535


//*****************************************************************************
//Fonctions CPU sort et verification
//*****************************************************************************
int verif_trie(int *tab,int size)
{
    for (int i=0; i<size-1; i=i+1)
      if (tab[i]>tab[i+1])
          return i;
    return -1;
    
}


void mergeSmall_k(int *A, int *B, int *M, int size_A, int size_B, int size_M)
{
  
  int i = 0;
  int j = 0;
  while (i+j<size_M)
  {  
    if (i>=size_A)
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


void sortManager_CPU(int *h_M,int h_size_A,int h_size_B,int h_slice_size,int i)
{
    
    /*Variables CPU*/ 
    int h_size_M_tmp= h_size_A+h_size_B;
    int *h_A;
    int *h_B;
    int *h_M_tmp;
    h_A=(int *)malloc(h_size_A*sizeof(int));
    h_B=(int *)malloc(h_size_B*sizeof(int));
    h_M_tmp=(int *)malloc(h_size_M_tmp*sizeof(int));

    /*Remplir A et B*/
    for (int j=0; j<h_size_A; j++)
      h_A[j] = h_M[i*h_slice_size+j];

    for (int j=0; j<h_size_B; j++)
      h_B[j] = h_M[i*h_slice_size+j+h_size_A];
 
    /*Sort*/
    if (h_size_A<h_size_B)
      mergeSmall_k(h_B, h_A, h_M_tmp, h_size_B, h_size_A, h_size_M_tmp);
    else
      mergeSmall_k(h_A, h_B, h_M_tmp, h_size_A, h_size_B, h_size_M_tmp);   
    
    
    /*Copie de h_M_tmp dans h_M*/
    for (int j=0; j<h_size_M_tmp; j++)
      h_M[i*h_slice_size+j]=h_M_tmp[j];
 
    
    /*Liberation*/
    free(h_A);
    free(h_B);
    free(h_M_tmp);

}


//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char const *argv[])
{
  //srand (time (NULL));
  srand (42);


  /*Déclaration des variables CPU*/
  /*Taille des tableaux*/
  int h_taille_M=1024*8;

  /*Traitement des options*/
  for (int i=0; i<argc-1; i=i+1)
  {
      if (strcmp(argv[i],"--s")==0 && atoi(argv[i+1])<N )
          h_taille_M=atoi(argv[i+1]);   
  }

  /*Tableaux et allocation memoire*/
  int *h_M;
  h_M=(int *)malloc(h_taille_M*sizeof(int));
 

  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_M;i++)
    h_M[i]=rand()%10000;

  /*Merge tableau*/
  /*variables generales*/
  int h_slice_size=1;
  int h_number_of_slices=h_taille_M/h_slice_size;
  int h_slice_reste_precedent=0;
  int h_slice_reste=0;
  
  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  /*Mise a jour taille et indices suite*/    
  cudaEventRecord(start);
  while (h_number_of_slices>0)
  {   
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
      /*Mise a jour taille et indices suite*/
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=h_taille_M%h_slice_size;
      h_number_of_slices=h_taille_M/h_slice_size;
      
      
      for (int i=0; i<h_number_of_slices; i++)
      {   
          sortManager_CPU(h_M,h_slice_size/2,h_slice_size/2,h_slice_size,i);
          
      }
      if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
      {
          int h_taille_A=h_slice_reste-h_slice_reste_precedent;
          int h_taille_B=h_slice_reste_precedent;
          sortManager_CPU(h_M,h_taille_A,h_taille_B,h_slice_size,h_number_of_slices);

      }
       
  }
  
  cudaEventRecord(stop);

  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"mergeBatches_seq Taille_M: %d, nbthreads: %d, numblocks: %d, Temps: %.5f, verif: %d\n", h_taille_M, threadsPerBlock, numBlocks, ms,verif_trie(h_M,h_taille_M));
  
  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==-1)
    printf("ok tableau trie");
  else
    printf("KO recommencer %d ",verif_trie(h_M,h_taille_M) );

  /*Liberation*/    
  free(h_M);


    return 0;
}