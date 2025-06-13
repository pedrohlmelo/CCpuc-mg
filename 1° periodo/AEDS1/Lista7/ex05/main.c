#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    char nome[20];
    char endereco[40];
    char telefone[16];

}Cliente;

void Preenche(Cliente vet[2])
{
    for(int i=0;i<2;i++)
    {
        scanf("%s",vet[i].nome);
        scanf("%s",vet[i].endereco);
        scanf("%s",vet[i].telefone);
    }

}

void Exibe(Cliente vet[2])
{
    for(int i =0;i<2;i++)
    {
        printf ("%s %s %s \n",vet[i].nome,vet[i].endereco,vet[i].telefone);
    }
}
int main()
{
    Cliente vet[2];
    Preenche(vet);
    Exibe(vet);


    return 0;
}
