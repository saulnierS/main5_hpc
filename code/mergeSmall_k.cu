//*****************************************************************************
//Projet HPC fusion et trie de tableaux sur GPU
//Auteur: ROBIN Clement et SAULNIER Solene
//Promo: MAIN5
//Date: decembre 2020
//Question 1
//*****************************************************************************

#include <stdio.h> 
#include <stdlib.h>
#include <string.h>
#define N 1024
#define threadsPerBlock 1024
//*****************************************************************************
//Fonctions CPU fusion et verification
//*****************************************************************************
int verif_trie(int *tab,int size)
{
    for (int i=0; i<size-1; i=i+1)
      if (tab[i]>tab[i+1])
          return i;
    return 1;
    
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
    if (compt1==deb2) //c'est que tous les elements du premier tableau ont ete utilises
    {
      break; //tous les elements ont donc ete classes
    }
    else if (compt2==(fin2+1)) //c'est que tous les elements du second tableau ont ete utilises
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
//Fonctions GPU (merge tableau)
//*****************************************************************************
__global__ void mergeSmall_k(int *A, int *B, int *M, int size_A, int size_B, int size_M)
{
    
    for( int i = blockIdx.x * blockDim.x  + threadIdx.x; i< size_M; i = i+ blockDim.x*gridDim.x)
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
}


 
//*****************************************************************************
//MAIN
//*****************************************************************************
int main(int argc, char *argv[]) {

  srand(42);
  int numThreads=threadsPerBlock;

  /*Declaration des variables CPU*/
  /*Taille des tableaux*/
  int h_taille_A=N-10;
  int h_taille_B=N-h_taille_A;
  int h_taille_M=h_taille_A+h_taille_B;

  for (int i=0; i<argc-1; i=i+1)
  {
      if (strcmp(argv[i],"--tailleA")==0 && atoi(argv[i+1])<N )
          h_taille_A=atoi(argv[i+1]);
      if (strcmp(argv[i],"--tailleB")==0 && atoi(argv[i+1])<N)
          h_taille_B=atoi(argv[i+1]);
      if (strcmp(argv[i],"--nbthreads")==0 && atoi(argv[i+1])<threadsPerBlock )
          numThreads=atoi(argv[i+1]);     
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
 

  /*Declaration des variables GPU*/ 
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


  /*Transfert la memoire du cpu vers le gpu*/
  cudaMemcpy(d_A, h_A, h_taille_A*sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, h_taille_B*sizeof(int), cudaMemcpyHostToDevice);

  /*Timer*/
  cudaEvent_t start, stop;
  cudaEventCreate(&start);
  cudaEventCreate(&stop);

  /*Merge tableau*/
  cudaEventRecord(start);
  mergeSmall_k<<<1,numThreads>>>(d_A, d_B, d_M, h_taille_A, h_taille_B, h_taille_M);
  cudaDeviceSynchronize();
  cudaEventRecord(stop);

 
  /*Transfert la memoire du gpu vers le cpu*/
  cudaMemcpy(h_M, d_M, h_taille_M*sizeof(int), cudaMemcpyDeviceToHost);
  
  /*Affichage du chrono*/
  cudaEventSynchronize(stop);
  float ms = 0;
  cudaEventElapsedTime(&ms, start, stop);
  fprintf(stderr,"mergeSmall_k Taille_A: %d, Taille_B: %d, Taille_M: %d, nbthreads: %d, Temps: %.5f, verif: %d\n", h_taille_A, h_taille_B, h_taille_M,numThreads,ms,verif_trie(h_M,h_taille_M));
  
  
  /*Verification*/
  if (verif_trie(h_M,h_taille_M)==1)
    printf("\n ok tableau M trie\n");
  else
    printf("\n KO probleme a l indice %d\n",verif_trie(h_M,h_taille_M));


  /*Liberation*/
  cudaFree(d_A);
  cudaFree(d_B);
  cudaFree(d_M);
  free(h_A);
  free(h_B);
  free(h_M);
 

    return 0;
} 