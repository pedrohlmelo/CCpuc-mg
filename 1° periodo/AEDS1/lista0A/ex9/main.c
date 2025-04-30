#include <stdio.h>
#include <stdlib.h>

int main()
{
    float numerador, denominador, resultado;
    printf("escreva o numerador e o denominador, respectivamente\n");
    scanf("%f%f",&numerador,&denominador);
    resultado = numerador / denominador;




        if (denominador == 0)
        {
            printf("o denominador nao pode ser 0");
        }
        else
        {
            printf("resultado %.2f", resultado);

        }

    return 0;
}
