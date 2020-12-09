//*****************************************************************************
//Projet HPC fusion et trie de tableaux sur GPU
//Auteur: ROBIN Clement et SAULNIER Solene
//Promo: MAIN5
//Date: decembre 2020
//Question 5 avec streams et utilisation de la shared
//*****************************************************************************

#include <stdio.h> 
#include <stdlib.h>
#define N 536870912 //taille max du tableau =d dans le projet
#define threadsPerBlock 1024
#define numBlocks 65535


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

//*****************************************************************************
//Fonctions GPU (merge tableau) small
//*****************************************************************************
__device__ void mergeSmallBatch_k(int *A, int *B, int *M, int size_A, int size_B, int size_M, int slice_size)
{

    int i = threadIdx.x;
    if (i < size_A+size_B)
    {

     /*Merge*/
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

__global__ void small_sortManager(int *M, int size_A, int size_B, int size_M, int number_of_slices)
{

      int slice_size = size_A + size_B;
        

      /*Chargement de A et B dans la shared memory*/
      /*Comme on a une seule shared memory*/
      __shared__ int shared_AB[1024];  //Comme A et B ne peuvent pas dépasser 1024
 
      int* s_A = (int*) &shared_AB[0];
      int* s_B = (int*) &s_A[size_A];
 
      __syncthreads();
 
      if (threadIdx.x < size_A)
        s_A[threadIdx.x] = M[blockIdx.x *slice_size+ threadIdx.x];

        

      if (threadIdx.x >= size_A && threadIdx.x < size_B + size_A  )
        s_B[threadIdx.x-size_A] = M[blockIdx.x *slice_size+ threadIdx.x]; 


      __syncthreads();
      /*if (size_A==1 && size_B==1)
      {
          //swap pour 2 elements
          if (threadIdx.x==0)
          {
              if (s_A[0]>s_B[0])
              {
                  M[blockIdx.x * 2]=s_B[0];
                  M[blockIdx.x * 2+1]=s_A[0];
              }
              else
              {
                  M[blockIdx.x * 2]=s_A[0];
                  M[blockIdx.x * 2+1]=s_B[0];
              }
          }
      }
      else*/ 
        mergeSmallBatch_k(s_A, s_B, M, size_A, size_B, size_M,slice_size);    
}

__global__ void small_sortManager_extraSlice(int *M ,int size_A,int size_B,int size_A_extra,int size_B_extra,int size_M,int number_of_slices)
{

        int slice_size = size_A + size_B;

      /*Chargement de A et B dans la shared memory*/
      /*Comme on a une seule shared memory*/
      __shared__ int shared_AB[1024];  //Comme A et B ne peuvent pas dépasser 1024
 
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
         /*
         if (size_A_extra==1 && size_B_extra==1)
         {
          //swap pour 2 elements
          if (threadIdx.x==0)
          {
              if (s_A[0]>s_B[0])
              {
                  M[blockIdx.x * 2]=s_B[0];
                  M[blockIdx.x * 2+1]=s_A[0];
              }
              else
              {
                  M[blockIdx.x * 2]=s_A[0];
                  M[blockIdx.x * 2+1]=s_B[0];
              }
            }
          }
          else*/
          //{ 
              if (size_A_extra < size_B_extra)
                mergeSmallBatch_k(s_B, s_A, M, size_B_extra, size_A_extra, size_M, slice_size);  
      
              else
                mergeSmallBatch_k(s_A, s_B, M, size_A_extra, size_B_extra, size_M, slice_size); 
          //}
     }

    else
    {
      /*if (size_A==1 && size_B==1)
      {
          //swap pour 2 elements
          if (threadIdx.x==0)
          {
              if (s_A[0]>s_B[0])
              {
                  M[blockIdx.x * 2]=s_B[0];
                  M[blockIdx.x * 2+1]=s_A[0];
              }
              else
              {
                  M[blockIdx.x * 2]=s_A[0];
                  M[blockIdx.x * 2+1]=s_B[0];
              }
          }
      }
      else */
         mergeSmallBatch_k(s_A, s_B, M, size_A, size_B, size_M,slice_size); 
    }
      
    
 
}

//*****************************************************************************
//Fonctions GPU (merge tableau) big
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
//****************************************************************************************************
// Fonctions CPU
//****************************************************************************************************
void sortManager_CPU(int *h_M,int h_size_A,int h_size_B,int h_slice_size,int i,cudaStream_t stream[])
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
 
    /*Sort*/
    if (h_size_A<h_size_B)
      sortManager_GPU<<<numBlocks,threadsPerBlock,0, stream[i]>>>(d_B, d_A, d_M_tmp, d_Path_tmp, h_size_B, h_size_A, h_size_M_tmp);
    else
      sortManager_GPU<<<numBlocks,threadsPerBlock,0, stream[i]>>>(d_A, d_B, d_M_tmp, d_Path_tmp, h_size_A, h_size_B, h_size_M_tmp);   
    
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
int main(int argc, char const *argv[])
{
  //srand (time (NULL));
  srand (42);


  /*Déclaration des variables CPU*/
  /*Taille des tableaux*/
  int h_taille_M=N;

  /*Traitement des options*/
  for (int i=0; i<argc-1; i=i+1)
  {
      if (strcmp(argv[i],"--s")==0 && atoi(argv[i+1])<N )
          h_taille_M=atoi(argv[i+1]);   
  }

  /*Tableaux et allocation memoire*/
  int *h_M;
  h_M=(int *)malloc(h_taille_M*sizeof(int));
 
  /*Déclaration des variables GPU*/  
  int *d_M;
  cudaMalloc(&d_M,h_taille_M*sizeof(int));

  /*Initialisation et preparation des tableaux*/
  for (int i=0; i<h_taille_M;i++)
    h_M[i]=rand()%10000;

  /*Merge tableau*/
  /*variables generales*/
  int h_slice_size=1;
  int h_number_of_slices=1024/2;
  int h_slice_reste_precedent=0;
  int h_slice_reste=0;
  
  /*Cas tailles de moins de 1024*/
  /*variables pour moins de 1024*/
  int h_is_irregular_batch=0;
  int h_irregular_batch_size=0;
  int h_irregular_slice_size=1;
  int h_irregular_number_of_slices=h_irregular_batch_size/2;
  int h_irregular_slice_reste_precedent=0;
  int h_irregular_slice_reste=0;


  /*Decoupage de M en batches de 1024*/
  int h_number_of_batches=h_taille_M/1024;
  if (h_taille_M%1024!=0)
  {
      h_irregular_batch_size=h_taille_M%1024;
      h_is_irregular_batch=1;
      h_irregular_number_of_slices=h_irregular_batch_size/2;   
  }
      

  /*Allocation et initialisation des batches*/
  /*Batches CPU*/
  int **h_batch_M;
  int *h_irregular_batch_M;
  h_batch_M = (int **) malloc( h_number_of_batches* sizeof(int *) );


  for (int b=0; b<h_number_of_batches; b++)
  {
    h_batch_M[b]=(int *) malloc (1024 * sizeof(int ));
    for (int ind=0; ind<1024; ind++)
        h_batch_M[b][ind]=h_M[b*1024+ind]; 
  }
  h_irregular_batch_M = (int *) malloc( h_irregular_batch_size* sizeof(int ) );
  for (int ind=0; ind<h_irregular_batch_size; ind++)
        h_irregular_batch_M[ind]=h_M[h_number_of_batches*1024+ind]; 
  
  /*Batches GPU*/
  int *d_batch_M;
  int *d_irregular_batch_M;
  cudaMalloc(&d_batch_M,1024*sizeof(int));
  cudaMalloc(&d_irregular_batch_M,h_irregular_batch_size*sizeof(int));
  

  /*Declaration et creation des streams*/
  cudaStream_t stream[h_number_of_batches+h_is_irregular_batch];
  for (int ind_stream=0; ind_stream<h_number_of_batches; ind_stream++)
      cudaStreamCreate(&stream[ind_stream]);
  if (h_is_irregular_batch==1)
      cudaStreamCreate(&stream[h_number_of_batches]);


  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  /*Slices inferieures a 1024*/
  cudaEventRecord(start);
  while (h_number_of_slices > 0)
  {   
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=1024%h_slice_size;
      h_number_of_slices=1024/h_slice_size;
      
      for (int b=0; b<h_number_of_batches;b++)
      {   
          cudaMemcpyAsync(d_batch_M, h_batch_M[b], 1024*sizeof(int), cudaMemcpyHostToDevice, stream[b]);
          
          if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
          {
              int h_taille_A_extra=h_slice_reste-h_slice_reste_precedent;
              int h_taille_B_extra=h_slice_reste_precedent;
              small_sortManager_extraSlice<<<h_number_of_slices+1,1024,0,stream[b]>>>(d_batch_M,h_slice_size/2,h_slice_size/2,h_taille_A_extra,h_taille_B_extra,1024,h_number_of_slices);
          }
          else
            small_sortManager<<<h_number_of_slices,1024,0,stream[b]>>>(d_batch_M, h_slice_size/2, h_slice_size/2,h_slice_size,h_number_of_slices);

          cudaMemcpyAsync(h_batch_M[b], d_batch_M, 1024*sizeof(int), cudaMemcpyDeviceToHost, stream[b]);
      }
      if (h_is_irregular_batch==1 && h_irregular_number_of_slices>0)
      {
          
           h_irregular_slice_size=2*h_irregular_slice_size;
           h_irregular_slice_reste_precedent=h_irregular_slice_reste;
           h_irregular_slice_reste=h_irregular_batch_size%h_irregular_slice_size;
           h_irregular_number_of_slices=h_irregular_batch_size/h_irregular_slice_size;

           cudaMemcpyAsync(d_irregular_batch_M, h_irregular_batch_M, h_irregular_batch_size*sizeof(int), cudaMemcpyHostToDevice, stream[h_number_of_batches]);

           if (h_irregular_slice_reste_precedent!=0 && h_irregular_slice_reste!=0)
           {
              
              int h_taille_A_extra=h_irregular_slice_reste-h_irregular_slice_reste_precedent;
              int h_taille_B_extra=h_irregular_slice_reste_precedent;
              small_sortManager_extraSlice<<<h_irregular_number_of_slices+1,h_irregular_batch_size,0,stream[h_number_of_batches]>>>(d_irregular_batch_M,h_irregular_slice_size/2,h_irregular_slice_size/2,h_taille_A_extra,h_taille_B_extra,h_irregular_batch_size,h_irregular_number_of_slices);

           }
           else
            small_sortManager<<<h_irregular_number_of_slices,h_irregular_batch_size,0,stream[h_number_of_batches]>>>(d_irregular_batch_M, h_irregular_slice_size/2, h_irregular_slice_size/2,h_irregular_slice_size,h_irregular_number_of_slices);
          
          cudaMemcpyAsync(h_irregular_batch_M, d_irregular_batch_M, h_irregular_batch_size*sizeof(int), cudaMemcpyDeviceToHost, stream[h_number_of_batches]);
          
      
      }
      

  }
  cudaDeviceSynchronize();

  /*re ecriture de M*/
  for (int b=0; b<h_number_of_batches; b++)
      for (int ind=0; ind<1024; ind++)
          h_M[b*1024+ind]=h_batch_M[b][ind];
  if (h_is_irregular_batch==1)
      for (int ind=0; ind<h_irregular_batch_size; ind++)
          h_M[h_number_of_batches*1024+ind]=h_irregular_batch_M[ind];
  
  
  /*Slices superieures a 1024*/

  /*Mise a jour taille et indices*/
  h_slice_size=1024;


  /*Destruction des streams qui ne servent pas*/
  for (int i=(h_taille_M/h_slice_size); i<h_number_of_batches+h_is_irregular_batch; i++)
      cudaStreamDestroy(stream[i]);
       

  /*Mise a jour taille et indices suite*/    
  h_number_of_slices=h_taille_M/h_slice_size;
  h_slice_reste=h_irregular_batch_size;
  int compteur=0;
  while (h_number_of_slices>0)
  {   
      compteur=compteur+1;
      /*Mise a jour taille et indices*/
      h_slice_size=2*h_slice_size;
   
      /*Destruction des streams qui ne servent pas*/
      if (compteur>1)
        for (int i=(h_taille_M/h_slice_size)+1; i<h_number_of_slices+1; i++)
          cudaStreamDestroy(stream[i]);
   
      /*Mise a jour taille et indices suite*/
      h_slice_reste_precedent=h_slice_reste;
      h_slice_reste=h_taille_M%h_slice_size;
      h_number_of_slices=h_taille_M/h_slice_size;
      
      
      for (int i=0; i<h_number_of_slices; i++)
      {   
          sortManager_CPU(h_M,h_slice_size/2,h_slice_size/2,h_slice_size,i, stream);
          
      }
      if (h_slice_reste_precedent!=0 && h_slice_reste!=0)
      {
          int h_taille_A=h_slice_reste-h_slice_reste_precedent;
          int h_taille_B=h_slice_reste_precedent;
          sortManager_CPU(h_M,h_taille_A,h_taille_B,h_slice_size,h_number_of_slices,stream);

      }
      cudaDeviceSynchronize();
       
  }
  
  cudaDeviceSynchronize();
  cudaEventRecord(stop);

  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"mergeBatches Taille_M: %d, nbthreads: %d, numblocks: %d, Temps: %.5f, verif: %d\n", h_taille_M, threadsPerBlock, numBlocks, ms,verif_trie(h_M,h_taille_M));
  
  /*Destructions des streams restants*/
  for (int i=0; i<h_number_of_slices; i++)
    cudaStreamDestroy(stream[i]);

  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==-1)
    printf("ok tableau trie");
  else
    printf("KO recommencer %d ",verif_trie(h_M,h_taille_M) );

  /*Liberation*/
  cudaFree(d_M);
  cudaFree(d_batch_M);
  cudaFree(d_irregular_batch_M);

  for (int b=0;b<h_number_of_batches;b++)
      free(h_batch_M[b]);
    
  free(h_M);
  free(h_batch_M);
  free(h_irregular_batch_M);


    return 0;
}