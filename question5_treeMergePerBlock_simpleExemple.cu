//%%writefile treeMergePerBlock_simpleExemple.cu
#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#include "fonctionsCPU.h"
#define N 100000
#define threadsPerBlock 1024
#define numBlock 65535
//*****************************************************************************
//Fonctions GPU (merge tableau)
//*****************************************************************************

__device__ void mergeSmallBatch_k(int *A, int *B, int *M, int size_A, int size_B, int size_M, int slice_size)
{

    int i = threadIdx.x;
    if (i < size_A+size_B)
    {
        //printf("\n blockIdx = %d, threadIdx = %d \n",blockIdx.x,threadIdx.x);
      
     
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
                      M[blockIdx.x * slice_size + i]=A[Q[1]];
                   //printf("\n blockIdx = %d, threadIdx = %d : M[%d] = A[%d]\n",blockIdx.x,threadIdx.x,blockIdx.x * slice_size + i,Q[1]);
                  }
                  else
                  {
                      M[blockIdx.x * slice_size + i]=B[Q[0]]; 
                    //printf("\n blockIdx = %d, threadIdx = %d : M[%d] = B[%d]\n",blockIdx.x,threadIdx.x,blockIdx.x * slice_size + i,Q[0]);
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

__global__ void sortManager(int *M, int size_A, int size_B, int size_M)
{
    
        int slice_size = size_A + size_B;
     
        int number_of_slices = size_M/slice_size;
        

          
  

       /*Chargement de A et B dans la shared memory*/
      /*Comme on a une seule shared memory*/
      __shared__ int shared_AB[1024];  //Comme A et B ne peuvent pas dépasser 1024
 
      int* s_A = (int*) &shared_AB[0];
      int* s_B = (int*) &s_A[size_A];
 
      __syncthreads();
 
      //int i = blockDim.x * blockIdx.x + threadIdx.x;
      if (threadIdx.x < size_A)
      {
          s_A[threadIdx.x] = M[blockIdx.x *slice_size+ threadIdx.x];
          //printf("\n blockIdx = %d, threadIdx = %d : s_A[%d] = M[%d] = %d\n",blockIdx.x,threadIdx.x,threadIdx.x, blockIdx.x *slice_size+ threadIdx.x, M[blockIdx.x *slice_size+ threadIdx.x]);
      }
        
 
      if (threadIdx.x >= size_A && threadIdx.x < size_B + size_A  )
      {
          s_B[threadIdx.x-size_A] = M[blockIdx.x *slice_size+ threadIdx.x]; 
          //printf("\n blockIdx = %d, threadIdx = %d : s_B[%d] = M[%d] = %d\n",blockIdx.x,threadIdx.x,threadIdx.x, blockIdx.x *slice_size+ threadIdx.x, M[blockIdx.x *slice_size+ threadIdx.x]);
      }
        

      __syncthreads();

      mergeSmallBatch_k(s_A, s_B, M, size_A, size_B, size_M,slice_size); 
  
 
   
}

 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char *argv[]) {
    
  srand (time (NULL));
  /*Déclaration des variables CPU*/
  /*Taille des tableaux*/

  int h_taille_M=8;
  
  printf("taille de M:%d \n",h_taille_M);

  /*Tableaux et allocation memoire*/
  int *h_M;
  h_M=(int *)malloc(h_taille_M*sizeof(int));
 

  /*Déclaration des variables GPU*/ 
  int *d_M;
  cudaMalloc(&d_M,h_taille_M*sizeof(int));
    

   
  /*Initialisation et preparation des tableaux*/

  h_M[0] = 8;
  h_M[1] = 4;
  h_M[2] = 12;
  h_M[3] = 2;
  h_M[4] = 2;
  h_M[5] = 1;
  h_M[6] = 5;
  h_M[7] = 7;



  /*Affichage*/

     printf("\n");
  printf("***M***\n");
  for (int i=0; i<h_taille_M; i=i+1)
    printf("%d\n",h_M[i]);

  /*Transfert la mémoire du cpu vers le gpu*/
  cudaMemcpy(d_M, h_M, h_taille_M*sizeof(int), cudaMemcpyHostToDevice);

  int h_slice_size = 2;
  int h_number_of_slices = h_taille_M / h_slice_size;
  /*Merge tableau*/
  sortManager<<<h_number_of_slices,8>>>(d_M, 1, 1, h_taille_M);


  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);

  printf("\n");
  printf("***M*** avec slice_size = %d\n",h_slice_size);
  for (int i=0; i<h_taille_M; i=i+1)
    printf("%d\n",h_M[i]);


  h_slice_size = 4;
  h_number_of_slices = h_taille_M / h_slice_size;
  sortManager<<<h_number_of_slices,8>>>(d_M, h_slice_size/2, h_slice_size/2, h_taille_M);


    printf("\n");
  printf("***M*** avec slice_size = %d\n",h_slice_size);
  for (int i=0; i<h_taille_M; i=i+1)
    printf("%d\n",h_M[i]);


  h_slice_size = 8;
  h_number_of_slices = h_taille_M / h_slice_size;
  sortManager<<<h_number_of_slices,8>>>(d_M, h_slice_size/2, h_slice_size/2, h_taille_M);

  /*Transfert la mémoire du gpu vers le cpu*/
  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);

  /*Affichage du resultat*/
  
  printf("\n");
  printf("***M*** avec slice_size = %d\n",h_slice_size);
  for (int i=0; i<h_taille_M; i=i+1)
    printf("%d\n",h_M[i]);
  
  if (verif_trie(h_M,h_taille_M)==1)
    printf("\n ok tableau trié\n");
    else
  {
    printf("\n KO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));
    //printf("%d %d %d %d\n",h_M[verif_trie(h_M,h_taille_M)-1],h_M[verif_trie(h_M,h_taille_M)], h_M[verif_trie(h_M,h_taille_M)+1], h_M[verif_trie(h_M,h_taille_M)+2] );
  }
 
  cudaFree(d_M);
  free(h_M);
 

    return 0;
}
    