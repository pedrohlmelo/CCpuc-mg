#include <stdio.h>
#include <stdlib.h>
int fatorial(int num)
{
    int fat = 1;

    for(int val = num;val>1; val --)
    {
        fat*=val;
    }
    return fat;
}

float calculaS(int N)
{
    float S = 0;
    for(int conta =1; conta<=N; conta++)
    {
        S=S+1.0/fatorial(conta);

    }
    return S;
}

int main()
{
    int quant;

    printf("Digite quantas parcelas:");
    scanf("%d",&quant);
    printf("O resultado eh %.2f\n",calculaS(quant));
    return 0;
}
