#include <stdio.h>
#include <stdlib.h>

typedef struct
{
   int codigo;
   char email[30];
   int horas;
   char pagina;

}Cliente;

void Preenche(Cliente vet[2])
{
    for(int i=0;i<2;i++)
    {
        scanf("%d",&vet[i].codigo);
        scanf("%s",vet[i].email);
        scanf("%d",&vet[i].horas);
        scanf(" %c",&vet[i].pagina);
    }
}

void Exibe(Cliente vet[2])
{
    float pagamento;
    int horast;
    for(int i=0;i<2;i++)
    {
        printf("Cliente %d: \n",i+1);
        printf("Codigo: %d\n",vet[i].codigo);
        printf("Email: %s\n",vet[i].email);
        printf("Horas de Acesso: %d\n",vet[i].horas);

        if(vet[i].horas >20)
        {
            pagamento = 35.00;
            horast = vet[i].horas -20;
            pagamento += (horast*2.50);
        }
        else pagamento = 35.00;

        if(vet[i].pagina == 'S')
        {
            pagamento += 40;
        }
        printf("Valor a Pagar: %.2f Quanzas\n",pagamento);
    }
}

int main()
{
    Cliente vet[2];
    Preenche(vet);
    Exibe(vet);

    return 0;
}
