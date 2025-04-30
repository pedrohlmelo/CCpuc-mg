#include <stdio.h>
#include <stdlib.h>

void exibirOrdemCrescente(int a, int b, int c)
{
    int menor, meio, maior;

    if (a <= b && a <= c)
    {
        menor = a;
        if (b <= c)
        {
            meio = b;
            maior = c;
        }
        else
        {
            meio = c;
            maior = b;
        }
    }
    else if (b <= a && b <= c)
    {
        menor = b;
        if (a <= c)
        {
            meio = a;
            maior = c;
        }
        else
        {
            meio = c;
            maior = a;
        }
    }
    else
    {
        menor = c;
        if (a <= b)
        {
            meio = a;
            maior = b;
        }
        else
        {
            meio = b;
            maior = a;
        }
    }

    printf("%d %d %d\n", menor, meio, maior);
}
int main()
{
    int j,s,z,n;
    //printf("Digite a quantidade de vezes\n");
    scanf("%d",&n);

    //printf("Digite os numeros\n");

    for(int y=0; y<n; y++)
    {
        scanf("%d %d %d",&j,&s,&z);
        exibirOrdemCrescente(j,s,z);
    }





    return 0;
}
