#include <stdio.h>
#include <stdlib.h>

int main()
{
    int conta =0,N;
    float num,soma=0;
    printf("digite quantos numero deseja somar para fazer a media ");
    scanf("%d",&N);

    do
    {
        printf("digite um numero ");
        scanf("%f",&num);

        soma += num;
        conta++;

    } while(conta<N);

    if(conta>0)
    {
        printf("A media eh %.2f ",soma/conta);
    }


    return 0;
}
