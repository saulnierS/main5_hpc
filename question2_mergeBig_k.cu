//%%writefile question2.cu
#include <stdio.h> 
#include <stdlib.h>
#include "fonctionsCPU.h"
#define N 67107840//taille max du tableau =d dans le projet
//#define N 10000
#define threadsPerBlock 1024
#define numBlock 65535
//*****************************************************************************
//Fonctions GPU (merge tableau)
//*****************************************************************************

__device__ void pathBig_k(int *A, int *B, int *Path, int size_A, int size_B, int size_M)
{
    for(int i = blockIdx.x * blockDim.x + threadIdx.x; i<size_M; i = i+blockDim.x*gridDim.x)
    {
      int K[2],P[2],Q[2];
      int offset;

      //if (i==0) printf("A: %d B:%d M:%d\n", size_A, size_B, size_M);
      if (i>size_A)
      {
          K[0]=i-size_A;
          K[1]=size_A;
          P[0]=size_A;
          P[1]=i-size_A;
      }
      else
      {
          K[0]=0;
          K[1]=i;
          P[0]=i;
          P[1]=0;
          //if (i==0) printf("K(%d,%d) et P(%d,%d)\n",K[0],K[1],P[0],P[1]);
      }
      while (1)
      {
          offset=abs(K[1]-P[1])/2;
          //if (i==0) printf("K(%d,%d) et P(%d,%d)\n",K[0],K[1],P[0],P[1]);
          Q[1]=K[1]-offset;
          Q[0]=K[0]+offset;
          if (Q[1] >= 0 && Q[0] <= size_B && (Q[1]== size_A || Q[0]==0 || A[Q[1]]>B[Q[0]-1]))//verif
          {
              if (Q[0]==size_B || Q[1]==0 || A[Q[1]-1]<=B[Q[0]])//verif
              {
                  if (Q[1]<size_A && (Q[0]==size_B || A[Q[1]]<=B[Q[0]]))//verif
                  {
                      Path[i]=1;//=on suit A (lignes verticales)
                      Path[i+size_M]=Q[1];
                  }
                  else
                  {
                      Path[i]=0;//=on suit B (lignes horizontales)
                      Path[i+size_M]=Q[0];
                  }
                  break;
              }
              else
              {
                  K[0]=Q[0]+1;
                  K[1]=Q[1]-1;
              }
          }
          else
          {
            P[0]=Q[0]-1;
            P[1]=Q[1]+1;
          }
      }
    }
}


__device__ void mergeBig_k(int *A, int *B, int *M,int *Path, int size_A, int size_B, int size_M)
{
    for(int i = blockIdx.x * blockDim.x + threadIdx.x; i<size_M; i = i+blockDim.x*gridDim.x)
    {
        if (Path[i]==1)
          M[i]=A[Path[i+size_M]];
        else if (Path[i]==0)
          M[i]=B[Path[i+size_M]];
        else
          printf("ERROR thread num %d block %d",i,blockIdx.x);
                  
    }
}

__global__ void sortManager(int *A, int *B, int *M, int *Path, int size_A, int size_B, int size_M)
{

    pathBig_k(A, B, Path, size_A, size_B, size_M);
    mergeBig_k(A, B, M, Path, size_A, size_B, size_M);
}
 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main() {
  srand (time (NULL));


  /*Déclaration des variables CPU*/

  /*Taille des tableaux*/
  int h_taille_A=rand()%(N-1)+1;//j ai rajouter 1 comme ca on peut pas piocher 0
  int h_taille_B=N-h_taille_A;//pour eviter d avoir 0 si on a piocher 10 normalement on ne devrait pas piocher 11
  int h_taille_M=h_taille_A+h_taille_B; //en fait je pense que c est plus le nombre de threads 
  
  printf("taille alea A:%d, B:%d N:%d",h_taille_A,h_taille_B,N);
  if (h_taille_A < h_taille_B)
  {
      int tpm=h_taille_A;
      h_taille_A=h_taille_B;
      h_taille_B=tpm;
  }

  /*Partie test*/
  /*int h_taille_A=9;
  int h_taille_B=7;
  int h_taille_M=16;
  */

  /*Tableaux et allocation memoire*/
  int *h_A;
  int *h_B;
  int *h_M;
  int *h_Path;
  h_A=(int *)malloc(h_taille_A*sizeof(int));
  h_B=(int *)malloc(h_taille_B*sizeof(int));
  h_M=(int *)malloc(h_taille_M*sizeof(int));
  h_Path=(int *)malloc(2*h_taille_M*sizeof(int));
 

  /*Déclaration des variables GPU*/ 
    int *d_A; 
    int *d_B; 
    int *d_M;
    int *d_Path;
    cudaMalloc(&d_A,h_taille_A*sizeof(int)); 
    cudaMalloc(&d_B,h_taille_B*sizeof(int));
    cudaMalloc(&d_M,h_taille_M*sizeof(int));
    cudaMalloc(&d_Path,2*h_taille_M*sizeof(int));
    

   
  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_A;i++)
  {
    h_A[i]=rand()%10000;
  }
  for (int i=0; i<h_taille_B;i++)
  {
    h_B[i]=rand()%10000;
  }
  
  tri_fusion(h_A, h_taille_A);
  tri_fusion(h_B, h_taille_B);


  //test(h_A, h_B);


  printf("\n");
  /*Affichage*/
  printf("***A***\n");
  for (int i=0; i<10; i=i+1)
    printf("%d\n",h_A[i]);
  printf("***B***\n");
  for (int i=0; i<10; i=i+1)
    printf("%d\n",h_B[i]);


  /*Transfert la mémoire du cpu vers le gpu*/
  cudaMemcpy(d_A, h_A, h_taille_A*sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, h_taille_B*sizeof(int), cudaMemcpyHostToDevice);
  //cudaMemcpy(d_M, h_M, h_taille_M*sizeof(int), cudaMemcpyHostToDevice);


  /*Merge tableau*/
  sortManager<<<numBlock,threadsPerBlock>>>(d_A, d_B, d_M, d_Path, h_taille_A, h_taille_B, h_taille_M);

  /*Transfert la mémoire du gpu vers le cpu*/
  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);

  /*Affichage du resultat*/
  printf("***M***\n");
  for (int i=0; i<10; i=i+1)
    printf("%d\n",h_M[i]);
  
  if (verif_trie(h_M,h_taille_M)==1)
    printf("\nok tableau trie\n");
  else
    printf("\nKO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));

  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_M);
  cudaFree(d_Path);
  free(h_A);
  free(h_B);
  free(h_M);
  free(h_Path);
 

    return 0;
} 