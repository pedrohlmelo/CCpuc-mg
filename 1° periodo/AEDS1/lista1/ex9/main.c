#include <stdio.h>
#include <stdlib.h>

int main()
{
    float preco;
    int codigo;

    //printf("Digite o preco do produto");
    scanf("%f",&preco);

    //printf("Digite o seu codigo de origem");
    scanf("%d",&codigo);

    switch(codigo)
    {
    case 1:printf("Sul");
        break;
    case 2:printf("Norte");
        break;
    case 3:printf("Leste");
        break;
    case 4:printf("Oeste");
        break;
    case 5:printf("Nordeste");
        break;
    case 6:printf("Nordeste");
        break;
    case 7:printf("Sudeste");
        break;
    case 8:printf("Sudeste");
        break;
    case 9:printf("Sudeste");
        break;

    default:
        if(codigo >=10 && codigo <=20)
        {
            printf("Sudoeste");
        }
        else if(codigo >=21 && codigo <=30)
        printf("Noroeste");

    }
    return 0;
}
