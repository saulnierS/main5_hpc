#include <stdio.h> 
#include <stdlib.h>
#define N 100000
#define threadsPerBlock 1024
#define numBlock 65535


//*****************************************************************************
//Fonctions CPU de verification
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

__device__ void pathBig_k(int *A, int *B, int *Path, int size_A, int size_B, int size_M)
{
    for(int i = blockIdx.x * blockDim.x + threadIdx.x; i<size_M; i = i+blockDim.x*gridDim.x)
    {
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
          if (Q[1] >= 0 && Q[0] <= size_B && (Q[1]== size_A || Q[0]==0 || A[Q[1]]>B[Q[0]-1]))
          {
              if (Q[0]==size_B || Q[1]==0 || A[Q[1]-1]<=B[Q[0]])
              {
                  if (Q[1]<size_A && (Q[0]==size_B || A[Q[1]]<=B[Q[0]]))
                  {
                      Path[i]=1;
                      Path[i+size_M]=Q[1];
                  }
                  else
                  {
                      Path[i]=0;
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

void sortManager_CPU(int *h_M,int h_size_A,int h_size_B,int h_slice_size,int i,cudaStream_t stream[])
{
    
    /*Variables CPU*/ 
    int h_size_M_tmp = h_size_A+h_size_B;
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
    cudaMemcpyAsync(d_A, h_A, h_size_A*sizeof(int), cudaMemcpyHostToDevice, stream[i]);
    cudaMemcpyAsync(d_B, h_B, h_size_B*sizeof(int), cudaMemcpyHostToDevice, stream[i]);
 
    /*Sort d une slice de M*/
    if (h_size_A<h_size_B)
    {

        sortManager_GPU<<<numBlock,threadsPerBlock,0, stream[i]>>>(d_B, d_A, d_M_tmp, d_Path_tmp, h_size_B, h_size_A, h_size_M_tmp);
    }
    else
    {

        sortManager_GPU<<<numBlock,threadsPerBlock,0, stream[i]>>>(d_A, d_B, d_M_tmp, d_Path_tmp, h_size_A, h_size_B, h_size_M_tmp);   
    }
    
    /*Transfert memoire GPU*/
    cudaMemcpyAsync(h_M_tmp, d_M_tmp, h_size_M_tmp*sizeof(int), cudaMemcpyDeviceToHost, stream[i]);

    /*Copie de h_M_tmp dans h_M*/
    for (int j=0; j<h_size_M_tmp; j++)
      h_M[i*h_slice_size+j]=h_M_tmp[j];
 
    
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

  srand (42);

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

  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);


  /*Sort de M*/
  int h_slice_size=1;
  int h_slice_number=h_taille_M/2;
  int h_slice_reste_precedent=0;
  int h_slice_reste=0;

  /*Declaration et creation des streams*/
  cudaStream_t stream[h_slice_number+1];

  for (int ind_stream=0; ind_stream<h_slice_number+1; ind_stream++)
      cudaStreamCreate(&stream[ind_stream]);  
      
  cudaEventRecord(start);
  while (h_slice_number > 0)
  {   
      
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
      
      /*Destruction des streams qui ne servent plus*/
      for (int i=(h_taille_M/h_slice_size)+1; i<h_slice_number+1; i++)
        cudaStreamDestroy(stream[i]);
      
      /*Mise a jour taille et indices suite*/
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=h_taille_M%h_slice_size;
      h_slice_number=h_taille_M/h_slice_size;
      
      
      for (int i=0; i<h_slice_number; i++) 
          sortManager_CPU(h_M,h_slice_size/2,h_slice_size/2,h_slice_size,i, stream);
          
      if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
      {
              int h_taille_A=h_slice_reste-h_slice_reste_precedent;
              int h_taille_B=h_slice_reste_precedent;
              sortManager_CPU(h_M,h_taille_A,h_taille_B,h_slice_size,h_slice_number,stream);

      }
      cudaDeviceSynchronize();

       
  }

  cudaDeviceSynchronize();
  cudaEventRecord(stop);

  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"question3 stream Taille_M: %d, nbthreads: %d, numblocks: %d, Temps: %.5f, verif: %d\n", h_taille_M, threadsPerBlock, numBlock, ms,verif_trie(h_M,h_taille_M));
  

  /*Destruction des streams restants*/
  for (int i=0; i<h_slice_number; i++)
    cudaStreamDestroy(stream[i]);

  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==1)
    printf("ok tableau trie");
  else
    printf("KO recommencer %d ",verif_trie(h_M,h_taille_M) );
  
  /*Liberation*/
  free(h_M);


    return 0;
}