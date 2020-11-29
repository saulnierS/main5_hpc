//%%writefile question3.cu
#include <stdio.h> 
#include <stdlib.h>
#include "fonctionsCPU.h"
#define N 100000 //taille max du tableau =d dans le projet
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

__global__ void sortManager_GPU(int *A, int *B, int *M,int *Path, int size_A, int size_B, int size_M)
{
    pathBig_k(A, B, Path, size_A, size_B, size_M);
    mergeBig_k(A, B, M, Path, size_A, size_B, size_M);
}

void sortManager_CPU(int *h_M,int h_size_A,int h_size_B,int h_slice_size,int i)
{
    
    //printf("\n***slice number***  %d\n", i);
    //printf("\n***slice size***  %d\n", h_slice_size);
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
    {
        h_A[j] = h_M[i*h_slice_size+j];
        //printf("\nindice A: %d indice M: %d",j,i*h_slice_size+j );
    }
        
    for (int j=0; j<h_size_B; j++)
    {
         h_B[j] = h_M[i*h_slice_size+j+h_size_A];
         //printf("\nindice B: %d indice M: %d",j,i*h_slice_size+h_size_A );
    }
    /* 
    printf("\nA\n");
    for (int j=0; j<h_size_A; j++)
        printf(" %d ", h_A[j]);
    printf("\nB\n");
    for (int j=0; j<h_size_B; j++)
        printf(" %d ", h_B[j]);
    printf("\n");
    */
 
    /*Variables GPU*/
    int *d_A;
    int *d_B;
    int *d_M_tmp;
    int *d_Path_tmp;
    cudaMalloc(&d_A,h_size_A*sizeof(int));
    cudaMalloc(&d_B,h_size_B*sizeof(int));
    cudaMalloc(&d_M_tmp,h_size_M_tmp*sizeof(int));
    cudaMalloc(&d_Path_tmp,h_size_M_tmp*sizeof(int));

  
    /*Transfert*/
    cudaMemcpy(d_A, h_A,h_size_A*sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B,h_size_B*sizeof(int), cudaMemcpyHostToDevice);
 
    /*Kernel*/
    if (h_size_A<h_size_B)
    {

        sortManager_GPU<<<numBlock,threadsPerBlock>>>(d_B, d_A, d_M_tmp, d_Path_tmp, h_size_B, h_size_A, h_size_M_tmp);
        cudaDeviceSynchronize();
    }
    else
    {

        sortManager_GPU<<<numBlock,threadsPerBlock>>>(d_A, d_B, d_M_tmp, d_Path_tmp, h_size_A, h_size_B, h_size_M_tmp);
        cudaDeviceSynchronize();    
    }
    
    /*Transfert memoire GPU*/
    cudaMemcpy(h_M_tmp, d_M_tmp, h_size_M_tmp*sizeof(int), cudaMemcpyDeviceToHost);

    /*Affichage du resultat*/
     /*     printf("\nMerge\n");
          for (int k=0; k<h_size_M_tmp; k=k+1)
            printf("%d , indice[%d]\n",h_M_tmp[k],k);
          if (verif_trie(h_M_tmp,h_size_M_tmp)==1)
            printf("ok tableau trie");
          else
            printf("KO tmp recommencer %d \n",verif_trie(h_M_tmp,h_size_M_tmp) );
     */
    /*Copie de h_M_tmp dans h_M*/
    //printf("\n***M***\n");
    for (int j=0; j<h_size_M_tmp; j++)
    {
        h_M[i*h_slice_size+j]=h_M_tmp[j];
        //printf("[%d] %d ,",i*h_slice_size+j,h_M_tmp[j] );
    }
    //printf("\n***************************\n");
    
    
    /*Liberation*/
    free(h_A);
    free(h_B);
    free(h_M_tmp);
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_M_tmp);
    cudaFree(d_Path_tmp);
}
//*****************************************************************************
//MAIN
//*****************************************************************************
int main() {
  srand (time (NULL));


  /*Déclaration des variables CPU*/
  /*Taille des tableaux*/
  //int h_taille_M=rand()%(N-1)+1;  
  //int h_taille_M=14; 
  int h_taille_M=N; 

  printf("Taille de M : %d\n",h_taille_M);

  /*Tableaux et allocation memoire*/
  int *h_M;
  h_M=(int *)malloc(h_taille_M*sizeof(int));
 
  /*Déclaration des variables GPU*/  
  int *d_M;
  cudaMalloc(&d_M,h_taille_M*sizeof(int));

  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_M;i++)
    h_M[i]=rand()%10000;

  //printf("***M***\n");
  //for (int i=0; i<h_taille_M; i=i+1)
    //printf("%d\n",h_M[i]);

  /*Merge tableau*/
  int h_slice_size=1;
  int h_slice_number=h_taille_M/2;
  int h_slice_reste_precedent=0;
  int h_slice_reste=0;
  while (h_slice_number > 0)
  {   
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
      
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=h_taille_M%h_slice_size;
      h_slice_number=h_taille_M/h_slice_size;
      

      for (int i=0; i<h_slice_number; i++)
      {   
          sortManager_CPU(h_M,h_slice_size/2,h_slice_size/2,h_slice_size,i);
          
      }
      if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
      {
              int h_taille_A=h_slice_reste-h_slice_reste_precedent;
              int h_taille_B=h_slice_reste_precedent;
              sortManager_CPU(h_M,h_taille_A,h_taille_B,h_slice_size,h_slice_number);

      }

      /*Affichage du resultat*/
      /*printf("***M***\n");
      for (int k=0; k<h_taille_M; k=k+1)
          printf("%d\n",h_M[k]);
      */

          
  }


  /*Affichage du resultat*/
  //printf("***M***\n");
  //for (int i=0; i<h_taille_M; i=i+1)
    //printf("%d\n",h_M[i]);
  if (verif_trie(h_M,h_taille_M)==1)
    printf("ok tableau trie");
  else
    printf("KO recommencer %d ",verif_trie(h_M,h_taille_M) );
  free(h_M);

 

    return 0;
}