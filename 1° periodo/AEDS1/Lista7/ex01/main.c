#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    char nome[20];
    int dia, mes;
} Pessoa;

void Preenche(Pessoa cadastro[40])
{
    for(int i=0; i<40; i++)
    {
        scanf("%s",cadastro[i].nome);
        scanf("%d",&cadastro[i].dia);
        scanf("%d",&cadastro[i].mes);
    }
}

void Exibe(Pessoa cadastro[40])
{
    for(int i=1; i<=12; i++)
    {
        printf("Aniversariantes do mes %d:\n",i);
        for(int j=0; j<40; j++)
        {
            if(cadastro[j].mes == i )
                printf("Nome: %s, Dia: %d\n",cadastro[j].nome,cadastro[j].dia);
        }


    }
}
int main()
{
    Pessoa cadastro[40];
    Preenche(cadastro);
    Exibe(cadastro);

    return 0;
}
