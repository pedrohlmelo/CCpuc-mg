#include <stdio.h>
#include <stdlib.h>

int main()
{
    int numero, inumero, centena, dezena, unidade;

    printf("digite um numero de 3 digitos\n");

    scanf("%d", &numero);

    centena = numero / 100;

    dezena = (numero / 10) %10;

    unidade = numero %10;

    inumero = unidade *100 + dezena*10  + centena;

    printf("O numero invertido :%d", inumero);








}

