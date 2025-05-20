#include <stdio.h>
#include <stdlib.h>
int divisao(int numerador, int denominador)
{
    if(numerador < denominador)
        return numerador % denominador;
    else
        return  divisao(numerador - denominador, denominador);
}
int main()
{
    int n,d,resultado;

    //printf("Digite o denominador e o numerador");
    scanf("%d%d",&n,&d);
    divisao(n,d);
    resultado = divisao(n,d);
    printf("%d",resultado);
    return 0;
}
