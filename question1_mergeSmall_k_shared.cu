//%%writefile question1_shared.cu
#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include "fonctionsCPU.h"
#define N 1024//taille max du tableau =d dans le projet
#define threadsPerBlock 1024
//*****************************************************************************
//Fonctions GPU (merge tableau)
//*****************************************************************************

__device__ void mergeSmall_k(int *A, int *B, int *M, int size_A, int size_B, int size_M)
{


    
    //for(int i = blockIdx.x * blockDim.x + threadIdx.x; i<size_M; i = i+blockDim.x*gridDim.x)
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i< size_M)
    {
      
     
     /*Merge*/
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
                      M[i]=A[Q[1]];
                  }
                  else
                  {
                      M[i]=B[Q[0]]; 
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
  //printf("pour %d on fait %d tours \n",blockIdx.x * blockDim.x + threadIdx.x,c);
}

__global__ void sortManager(int *A, int *B, int *M, int size_A, int size_B, int size_M)
{
    /*Chargement de A et B dans la shared memory*/
    /*Comme on a une seule shared memory*/
    __shared__ int shared_AB[N];
 
    int* s_A = (int*) &shared_AB[0];
    int* s_B = (int*) &s_A[size_A];
 
    __syncthreads();
 
    int i = blockDim.x * blockIdx.x + threadIdx.x;
 
    if (i < size_A)
        s_A[i] = A[i];
 
    if (i < size_B)
      s_B[i] = B[i];
 
    __syncthreads();

    mergeSmall_k(s_A, s_B, M, size_A, size_B, size_M);
}

 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char *argv[]) {
    
  srand (time (NULL));
  int numThreads=threadsPerBlock;
  /*Déclaration des variables CPU*/
  /*Taille des tableaux*/

  int h_taille_A=rand()%(N-1)+1;//j ai rajouter 1 comme ca on peut pas piocher 0
  int h_taille_B=N-h_taille_A;//pour eviter d avoir 0 si on a piocher 10 normalement on ne devrait pas piocher 11
  int h_taille_M=h_taille_A+h_taille_B; //en fait je pense que c est plus le nombre de threads 

  for (int i=0; i<argc-1; i=i+1)
  {
      if (strcmp(argv[i],"--tailleA")==0 && atoi(argv[i+1])<N )
          h_taille_A=atoi(argv[i+1]);
      if (strcmp(argv[i],"--tailleB")==0 && atoi(argv[i+1])<N)
          h_taille_B=atoi(argv[i+1]);
      if (strcmp(argv[i],"--tailleA")==0 && atoi(argv[i+1])<threadsPerBlock )
          numThreads=atoi(argv[i+1]);
      //printf("%d %d\n",i,strcmp(argv[i],"--tailleA"));  
  }
  printf("taille alea A:%d, B:%d N:%d",h_taille_A,h_taille_B,N);
  if (h_taille_A < h_taille_B)
  {
      int tpm=h_taille_A;
      h_taille_A=h_taille_B;
      h_taille_B=tpm;
  }
  /*Partie test*/
  /*
  int h_taille_A=9;
  int h_taille_B=7;
  int h_taille_M=16;
  */

  /*Tableaux et allocation memoire*/
  int *h_A;
  int *h_B;
  int *h_M;
  h_A=(int *)malloc(h_taille_A*sizeof(int));
  h_B=(int *)malloc(h_taille_B*sizeof(int));
  h_M=(int *)malloc(h_taille_M*sizeof(int));
 

  /*Déclaration des variables GPU*/ 
  int *d_A; 
  int *d_B; 
  int *d_M;
  cudaMalloc(&d_A,h_taille_A*sizeof(int)); 
  cudaMalloc(&d_B,h_taille_B*sizeof(int));
  cudaMalloc(&d_M,h_taille_M*sizeof(int));
    

   
  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_A;i++)
    h_A[i]=rand()%10000;
  
  for (int i=0; i<h_taille_B;i++)
    h_B[i]=rand()%10000;
  
  tri_fusion(h_A, h_taille_A);
  tri_fusion(h_B, h_taille_B);


  //test(h_A, h_B);


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
  cudaMemcpy(d_M, h_M, h_taille_M*sizeof(int), cudaMemcpyHostToDevice);


  /*Merge tableau*/
  sortManager<<<1,numThreads>>>(d_A, d_B, d_M, h_taille_A, h_taille_B, h_taille_M);

  /*Transfert la mémoire du gpu vers le cpu*/
  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);

  /*Affichage du resultat*/
  printf("***M***\n");
  for (int i=0; i<10; i=i+1)
    printf("%d\n",h_M[i]);

  if (verif_trie(h_M,h_taille_M)==1)
    printf("\n ok tableau trie\n");
    else
  {
    printf("\n KO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));
    printf("%d %d %d %d\n",h_M[verif_trie(h_M,h_taille_M)-1],h_M[verif_trie(h_M,h_taille_M)], h_M[verif_trie(h_M,h_taille_M)+1], h_M[verif_trie(h_M,h_taille_M)+2] );
  }
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_M);
  free(h_A);
  free(h_B);
  free(h_M);
 

    return 0;
} 