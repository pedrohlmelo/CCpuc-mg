#include <stdio.h>
#include <stdlib.h>

int main()
{
    float num,soma,conta,quantidade;
    soma=0;
    conta=0;

    printf("digite a quantidade de numeros que vc quer somar para fazer a media ");
    scanf("%f",&quantidade);

    while(conta<quantidade)
    {
        printf("digite um numero ");
        scanf("%f",&num);

        soma = soma + num;
        conta++;
    }
    printf("A media eh %.2f",soma/conta);



    return 0;
}
