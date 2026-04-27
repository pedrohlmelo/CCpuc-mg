#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    char nome[20];
    char telefone[14];
    float preco;
} Loja;

void Preenche(Loja vet[15])
{
    for(int i=0; i<15; i++)
    {
        scanf("%s",vet[i].nome);
        scanf("%s",vet[i].telefone);
        scanf("%f",&vet[i].preco);
    }
}


void Exibe(Loja vet[15])
{
    float soma=0;
    for(int i=0; i<15; i++)
    {
        soma+=vet[i].preco;
    }
    float media = soma/15;
    printf("A media dos precos cadastrados eh: %.2f\n",media);
    printf("Lojas com precos abaixo da media: \n");
    for(int i=0; i<15; i++)
    {
        if((vet+i)->preco < media)
        {
            printf("Nome: %s\n",vet[i].nome);
            printf("Telefone: %s\n",vet[i].telefone);
        }
    }
}

int main()
{
    float media;
    Loja vet[15];
    Preenche(vet);
    Exibe(vet);

    return 0;
}
