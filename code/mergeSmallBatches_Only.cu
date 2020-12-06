//*****************************************************************************
//Projet HPC fusion et trie de tableaux sur GPU
//Auteur: ROBIN Clement et SAULNIER Solene
//Promo: MAIN5
//Date: decembre 2020
//Question 5 mais seulement pour des batches de moins de 1024
//*****************************************************************************


#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#define N 1024
#define threadsPerBlock 1024
#define numBlock 65535

//*****************************************************************************
//Fonctions CPU verification
//*****************************************************************************
int verif_trie(int *tab,int size)
{
    for (int i=0; i<size-1; i=i+1)
      if (tab[i]>tab[i+1])
          return i;
    return 1;
    
}

//*****************************************************************************
//Fonctions GPU (merge tableau)
//*****************************************************************************

__device__ void mergeSmallBatch_k(int *A, int *B, int *M, int size_A, int size_B, int size_M, int slice_size)
{

    for(int i = threadIdx.x; i<size_A+size_B; i = i+blockDim.x*gridDim.x)
    {  
     
      /*Merge batches*/
      int K[2],P[2],Q[2];
      int offset;

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
          
      }
      while (1)
      {
          offset=abs(K[1]-P[1])/2;
          Q[1]=K[1]-offset;
          Q[0]=K[0]+offset;
          if (Q[1] >= 0 && Q[0] <= size_B && (Q[1]== size_A || Q[0]==0 || A[Q[1]]>B[Q[0]-1]))//verif
          {
              if (Q[0]==size_B || Q[1]==0 || A[Q[1]-1]<=B[Q[0]])//verif
              {
                  if (Q[1]<size_A && (Q[0]==size_B || A[Q[1]]<=B[Q[0]]))
                      M[blockIdx.x * slice_size + i]=A[Q[1]];
                  else
                      M[blockIdx.x * slice_size + i]=B[Q[0]]; 
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

__global__ void sortManager(int *M, int size_A, int size_B, int size_M, int number_of_slices)
{

      int slice_size = size_A + size_B;
        

      /*Chargement de A et B dans la shared memory*/
      /*Comme on a une seule shared memory*/
      __shared__ int shared_AB[1024];  //Comme A et B ne peuvent pas depasser 1024
 
      int* s_A = (int*) &shared_AB[0];
      int* s_B = (int*) &s_A[size_A];
 
      __syncthreads();
 
      if (threadIdx.x < size_A)
        s_A[threadIdx.x] = M[blockIdx.x *slice_size+ threadIdx.x];
        
 
      if (threadIdx.x >= size_A && threadIdx.x < size_B + size_A  )
        s_B[threadIdx.x-size_A] = M[blockIdx.x *slice_size+ threadIdx.x]; 

      __syncthreads();

      mergeSmallBatch_k(s_A, s_B, M, size_A, size_B, size_M,slice_size); 
  
}

__global__ void sortManager_extraSlice(int *M ,int size_A,int size_B,int size_A_extra,int size_B_extra,int size_M,int number_of_slices)
{

      int slice_size = size_A + size_B;

      /*Chargement de A et B dans la shared memory*/
      /*Comme on a une seule shared memory*/
      __shared__ int shared_AB[1024];  //Comme A et B ne peuvent pas depasser 1024
 
      int* s_A = (int*) &shared_AB[0];
     
      int* s_B;
     
      if (blockIdx.x == number_of_slices)
        s_B = (int*) &s_A[size_A_extra];

      else
        s_B = (int*) &s_A[size_A];
 
      __syncthreads();

      if (threadIdx.x < size_A)
        s_A[threadIdx.x] = M[blockIdx.x *slice_size+ threadIdx.x]; 
 
      if (threadIdx.x >= size_A && threadIdx.x < size_B + size_A)
        s_B[threadIdx.x-size_A] = M[blockIdx.x *slice_size+ threadIdx.x]; 

      if (blockIdx.x == number_of_slices && threadIdx.x < size_A_extra)
        s_A[threadIdx.x] = M[blockIdx.x *slice_size+ threadIdx.x];
     
      if (blockIdx.x == number_of_slices && threadIdx.x >= size_A_extra && threadIdx.x < size_B_extra + size_A_extra)
        s_B[threadIdx.x-size_A_extra] = M[blockIdx.x *slice_size+ threadIdx.x]; 

      __syncthreads();

     if (blockIdx.x == number_of_slices)
     {
        if (size_A_extra < size_B_extra)
          mergeSmallBatch_k(s_B, s_A, M, size_B_extra, size_A_extra, size_M, slice_size);  
      
        else
          mergeSmallBatch_k(s_A, s_B, M, size_A_extra, size_B_extra, size_M, slice_size); 
     }

    else
      mergeSmallBatch_k(s_A, s_B, M, size_A, size_B, size_M,slice_size); 
    
 
}

 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char *argv[]) {
    
  srand (time (NULL));

  /*Declaration des variables CPU*/
  /*Taille des tableaux*/
  int h_taille_M=N; 

  /*Tableaux et allocation memoire*/
  int *h_M;
  h_M=(int *)malloc(h_taille_M*sizeof(int));

  /*Declaration des variables GPU*/ 
  int *d_M;  
  cudaMalloc(&d_M,h_taille_M*sizeof(int));

  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_M;i++)
    h_M[i]=rand()%10000;


  /*Transfert la memoire du cpu vers le gpu*/
  cudaMemcpy(d_M, h_M, h_taille_M*sizeof(int), cudaMemcpyHostToDevice);


  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  /*Merge*/
  int h_slice_size=1;
  int h_number_of_slices=h_taille_M/2;
  int h_slice_reste_precedent=0;
  int h_slice_reste=0;


  cudaEventRecord(start);
  while (h_number_of_slices > 0)
  {   
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=h_taille_M%h_slice_size;
      h_number_of_slices=h_taille_M/h_slice_size;
      
   
      if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
      {
          int h_taille_A_extra=h_slice_reste-h_slice_reste_precedent;
          int h_taille_B_extra=h_slice_reste_precedent;
          sortManager_extraSlice<<<h_number_of_slices+1,h_taille_M>>>(d_M,h_slice_size/2,h_slice_size/2,h_taille_A_extra,h_taille_B_extra,h_taille_M,h_number_of_slices);
      }
      else
        sortManager<<<h_number_of_slices,h_taille_M>>>(d_M, h_slice_size/2, h_slice_size/2,h_slice_size,h_number_of_slices);

  }
  cudaDeviceSynchronize();
  cudaEventRecord(stop);



  /*Transfert la memoire du gpu vers le cpu*/
  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);


  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"mergeSmallBatch_Only Taille_M: %d, nbthreads: %d, numblocks: %d, Temps: %.5f, verif: %d\n", h_taille_M,threadsPerBlock,numBlock,ms,verif_trie(h_M,h_taille_M));
  


  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==1)
    printf("\n ok tableau trie\n");
  else
    printf("\n KO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));
   
  /*Liberation*/
  cudaFree(d_M);
  free(h_M);
 

    return 0;
}