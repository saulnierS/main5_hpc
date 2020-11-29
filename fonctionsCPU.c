#include <stdio.h> 
#include <stdlib.h>
//*****************************************************************************
//Fonctions CPU (trie de tableau)
//*****************************************************************************
void trie_a_bulle(int *tab,int size)
{
    int end=1;
    int tpm;
    while(end==1)
    {
      end=0;
      for(int i=0; i<size-1; i=i+1)
      {
          if (tab[i]>tab[i+1])
          {
              end=1;
              tpm=tab[i];
              tab[i]=tab[i+1];
              tab[i+1]=tpm;
              
          }
      }
     
    }
}
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

        //on recopie les éléments du début du tableau
        for(i=deb1;i<=fin1;i++)
            {
            table1[i-deb1]=tableau[i];
            }
                        
        for(i=deb1;i<=fin2;i++)
            {        
            if (compt1==deb2) //c'est que tous les éléments du premier tableau ont été utilisés
                {
                break; //tous les éléments ont donc été classés
                }
            else if (compt2==(fin2+1)) //c'est que tous les éléments du second tableau ont été utilisés
                {
                tableau[i]=table1[compt1-deb1]; //on ajoute les éléments restants du premier tableau
                compt1++;
                }
            else if (table1[compt1-deb1]<tableau[compt2])
                {
                tableau[i]=table1[compt1-deb1]; //on ajoute un élément du premier tableau
                compt1++;
                }
            else
                {
                tableau[i]=tableau[compt2]; //on ajoute un élément du second tableau
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

void fusion_merde (int* a, int n, int m) {
    int i, j, k;
    int* x = (int*)malloc(n * sizeof (int));
    for (i = 0, j = m, k = 0; k < n; k++) {
        x[k] = j == n      ? a[i++]
             : i == m      ? a[j++]
             : a[j] < a[i] ? a[j++]
             :               a[i++];
    }
    for (i = 0; i < n; i++) {
        a[i] = x[i];
    }
    free(x);
}
 
void tri_fusion_merde (int* liste, int taille) {
    if (taille < 2) return;
    int milieu = taille / 2;

    int* tab_left= (int *) malloc(milieu * sizeof(int));
    int* tab_right = (int *) malloc(taille-milieu * sizeof(int));


    for(int i = 0 ; i < milieu; i++)
    {
        tab_left[i] = liste[i];
    }
    for(int i = milieu ; i < taille; i++)
    {
        tab_right[i-milieu] = liste[i];
    }

    tri_fusion(tab_left, milieu);
    tri_fusion(tab_right, taille - milieu);

        for(int i = 0 ; i < milieu; i++)
    {
        liste[i] = tab_left[i];
    }
    for(int i = milieu ; i < taille; i++)
    {
        liste[i] = tab_right[i-milieu];
    }

    fusion_merde(liste, taille, milieu);

    free(tab_left);
    free(tab_right);
}


void tri_fusion_solene(int *tab, int size) 
{
    //on a 1 seul case
    if(size<2) 
      return;
    /*preparation des sous tableaux*/
    int size_left=size/2;
    int size_right= size-size_left;
    int *tab_left;
    int *tab_right;

 
    tab_left= (int *) malloc(size_left * sizeof(int));
    tab_right = (int *) malloc(size_right * sizeof(int));
 
    if(tab_left == NULL || tab_right == NULL)
    {
        printf("Probleme trie fusion sous tableau nulle");
        
    }
 
    /*remplissage du tableau de gauche*/
    for(int i = 0 ; i < size_left; i++)
    {
        tab_left[i] = tab[i];
    }
    /*remplissage du tableau de droite*/
    int ind=0;
    for(int i = size_left ; i < size; i++)
    {
        tab_right[ind] = tab[i];
        ind=ind+1;
    }
    /*recursion gauche*/
    tri_fusion(tab_left, size_left);
    /*recursion droite*/
    tri_fusion(tab_right, size_right);

    /*remplissage du tableau*/
    int i = 0, j = 0, k = 0;
    while(i < size_left && j < size_right)
    {
        if(tab_left[i] < tab_right[j])
        {
            tab[k] = tab_left[i];
            i++;//on va a la case suivante tu tableau de gauche
            k++;//on augmente indice du tableau
        }
        else if(tab_left[i] > tab_right[j])
        {
            tab[k] = tab_right[j];
            j++;//on va a la case suivante tu tableau de droite
            k++;//on augmente indice du tableau
        }
        else
        {
            tab[k] = tab_left[i];
            k++;//on augmente indice du tableau
            i++;//on va a la case suivante tu tableau de gauche
            j++;//on va a la case suivante tu tableau de droite
        }
    }
    //si les tableaux n ont pas la meme taille on complete
    while(i < size_left)
    {
        tab[k] = tab_left[i];
        k++;
        i++;
    }
 
 
    while(j < size_right)
    {
        tab[k] = tab_right[j];
        k++;
        j++;
    }
    free(tab_left);
    free(tab_right);
}

void test(int *A,int *B)
{
    A[0]=1;
    A[1]=2;
    A[2]=5;
    A[3]=6;
    A[4]=6;
    A[5]=9;
    A[6]=11;
    A[7]=15;
    A[8]=16;
 
    B[0]=4;
    B[1]=7;
    B[2]=8;
    B[3]=10;
    B[4]=12;
    B[5]=13;
    B[6]=14;
 
 
}
