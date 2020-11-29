//%%writefile question4.cu
#include <stdio.h> 
#include <stdlib.h>
#include "fonctionsCPU.h"
#define N 67107840//taille max du tableau =d dans le projet
#define threadsPerBlock 1024
#define numBlock 65535
//*****************************************************************************
//Fonctions GPU (merge tableau)
//*****************************************************************************

__global__ void pathBig_k(int *A, int *B, int *Path, int size_A, int size_B, int size_M)
{
    for(int i = blockIdx.x * blockDim.x + threadIdx.x; i<size_M; i = i+blockDim.x*gridDim.x)
    {
      int K[2],P[2],Q[2];
      int offset;

      if (i==0) printf("A: %d B:%d M:%d\n", size_A, size_B, size_M);
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
          if (i==0) printf("K(%d,%d) et P(%d,%d)\n",K[0],K[1],P[0],P[1]);
      }
      while (1)
      {
          offset=(K[1]-P[1])/2;
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


__global__ void mergeBig_k(int *A, int *B, int *M,int *Path, int size_A, int size_B, int size_M)
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
//*****************************************************************************
//MAIN
//*****************************************************************************
int main() {
    srand (time (NULL));
    /*Déclaration des variables CPU*/
    /*Partie test*/
    
      int h_nb_tab=3000;

      int h_taille_A=9;
      int h_taille_B=7; 
      int h_taille_M=16;
      int h_taille_M_total=h_nb_tab*(h_taille_A+h_taille_B);   
  

    /*Tableaux et allocation memoire*/
    int **h_A;
    int **h_B;
    int **h_M;
    int **h_Path;
    int *h_M_total;

    /*Alloction memoire*/
    h_A = (int **) malloc( h_nb_tab* sizeof(int *) );
    h_B = (int **) malloc( h_nb_tab* sizeof(int *) );
    h_M = (int **) malloc( h_nb_tab* sizeof(int *) );
    h_Path = (int **) malloc( h_nb_tab* sizeof(int *) );
    h_M_total = (int *) malloc(h_taille_M_total* sizeof(int));

    /*Choix aleatoire des tailles des tableaux*/
    for (int i=0; i<h_nb_tab; i=i+1)
    {
        /*Alloction memoire*/
        h_A[i]=(int *)malloc(h_taille_A*sizeof(int));
        h_B[i]=(int *)malloc(h_taille_B*sizeof(int)); 
        h_M[i]=(int *)malloc(h_taille_M*sizeof(int)); 
        h_Path[i]=(int *)malloc(h_taille_M*sizeof(int));

    }
  

    /*Initialisation et preparation des tableaux*/
    for (int i=0; i<h_nb_tab;i++)
    {
        for(int j=0; j<h_taille_A;j++)
          h_A[i][j]=rand()%10000;
        for(int j=0; j<h_taille_B;j++)
          h_B[i][j]=rand()%10000;
    }

    /*Trie des tableaux*/
    for (int i=0; i<h_nb_tab;i++)
    {
        tri_fusion(h_A[i], h_taille_A);
        tri_fusion(h_B[i], h_taille_B);
    }

    /*Affichage*/
    
    printf("\n***A***\n");
    for (int i=0; i<h_nb_tab;i++)
    {
        printf("\ntaille du tableau %d : %d\n",i,h_taille_A);
        for(int j=0; j<h_taille_A;j++)
          printf("%d,",h_A[i][j]);
    }
    printf("\n***B***\n");
    for (int i=0; i<h_nb_tab;i++)
    {
        printf("\ntaille du tableau %d : %d\n",i,h_taille_B);
        for(int j=0; j<h_taille_B;j++)
          printf("%d,",h_B[i][j]);
    }
    
    /*Declaration variable GPU*/
    int *d_A; 
    int *d_B; 
    int *d_M;
    int *d_Path;
    int *d_M_total;
    //cudaStream_t stream;

    /*Alloction memoire*/
    cudaMalloc(&d_A,h_taille_A*sizeof(int));
    cudaMalloc(&d_B,h_taille_B*sizeof(int));
    cudaMalloc(&d_M,h_taille_M*sizeof(int));
    cudaMalloc(&d_Path,h_taille_M*sizeof(int));
    cudaMalloc(&d_M_total,h_taille_M_total*sizeof(int));

    
    for (int i=0; i<h_nb_tab;i++)
    {
        /*Transfert la mémoire du cpu vers le gpu*/
        cudaMemcpy(d_A, h_A[i], h_taille_A*sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_B, h_B[i], h_taille_B*sizeof(int), cudaMemcpyHostToDevice);
        /*Merge tableau*/
        pathBig_k<<<numBlock,threadsPerBlock>>>(d_A, d_B, d_Path, h_taille_A, h_taille_B, h_taille_M);
        cudaDeviceSynchronize();
        mergeBig_k<<<numBlock,threadsPerBlock>>>(d_A, d_B, d_M, d_Path, h_taille_A, h_taille_B, h_taille_M);
        /*Transfert la mémoire du gpu vers le cpu*/
        cudaMemcpy(h_M[i], d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);
        cudaDeviceSynchronize();
    }
    int h_taille_tpm=0;
    int *h_tpm;
    int *d_tpm;
    int *d_Path_tpm;
    for (int j=0; j<h_taille_M; j++)
            h_M_total[j]=h_M[0][j];
    for (int i=0;i<h_nb_tab-1; i=i+1)
    {
        /*Preparation de la memoire*/
        h_taille_tpm+=h_taille_M;
        h_tpm=(int *)malloc(h_taille_tpm*sizeof(int));
        cudaMalloc(&d_tpm,h_taille_tpm*sizeof(int));
        cudaMalloc(&d_Path_tpm,(h_taille_M+h_taille_tpm)*sizeof(int));
        for (int j=0; j<h_taille_tpm; j++)
            h_tpm[j]=h_M_total[j];
        
        
        /*Transfert la memoire du cpu vers le gpu*/
        cudaMemcpy(d_tpm, h_tpm, h_taille_tpm*sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(d_M, h_M[i+1], h_taille_M*sizeof(int), cudaMemcpyHostToDevice);
        
        
        /*Merge tableau*/
        pathBig_k<<<numBlock,threadsPerBlock>>>(d_tpm, d_M, d_Path_tpm, h_taille_tpm, h_taille_M, h_taille_tpm+h_taille_M);
        cudaDeviceSynchronize();
        mergeBig_k<<<numBlock,threadsPerBlock>>>(d_tpm, d_M, d_M_total, d_Path_tpm, h_taille_tpm, h_taille_M, h_taille_tpm+h_taille_M);
        
        
        /*Transfert la mémoire du gpu vers le cpu*/
        cudaMemcpy(h_M_total, d_M_total, (h_taille_tpm+h_taille_M)*sizeof(int), cudaMemcpyDeviceToHost);
        cudaDeviceSynchronize();
        cudaFree(d_tpm);
        cudaFree(d_Path_tpm);
        free(h_tpm);
        
    }
    
    

    /*Affichage du resultat*/
    printf("\n***M***\n");
    for (int i=0; i<h_nb_tab; i++)
    {
        for (int j=0;j<h_taille_M;j++)
          printf("%d,",h_M[i][j]);
        printf("\n");
    }
    printf("\n***M tot***\n");
    for (int i=0; i<h_taille_M_total; i++)
    {
          printf("%d,",h_M_total[i]);
    }

    if (verif_trie(h_M_total,h_taille_M_total)==1)
      printf("\nok tableau trie\n");
    else
      printf("\nKO recommencer\n");

    /*Liberation de la memoire GPU*/
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_M);
    cudaFree(d_Path);
    cudaFree(d_M_total);


    /*Liberation de la memoire CPU*/
    for(int i=0; i<h_nb_tab;i++)
    {
      free(h_A[i]);
      free(h_B[i]);
      free(h_M[i]);
      free(h_Path[i]);
    }
    free(h_A);
    free(h_B);
    free(h_M);
    free(h_Path);
    free(h_M_total);
    

   
  

    return 0;
} 