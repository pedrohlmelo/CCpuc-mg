#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    int area;
    int codigo;
    char doacao;
    char nomeobra[20];
    char nomeautor[20];
    char editora[20];

}Livro;

void Preenche(Livro vet[1500])
{
   for(int i=0;i<1500;i++)
   {
       scanf("%d",&vet[i].area);
       scanf("%d",&vet[i].codigo);
       scanf(" %c",&vet[i].doacao);
       scanf("%s",vet[i].nomeautor);
       scanf("%s",vet[i].nomeautor);
   }
}

void Exibe(Livro vet[1500])
{
    for(int i=0;i<1500;i++)
   {
       if(area == 1)
       {
           printf("Areas: Exatas");
       }
       else if(area == 2)
       {
           printf("Areas: humanas");
       }
       else printf("Areas: biologicas");
   }
}

int main()
{
    Livro vet[1500];
    Preenche(vet);
    Exibe(vet);
    return 0;
}
