#include <stdio.h>
#include <stdlib.h>

int main()
{
    FILE *arquivo = fopen("entrada.txt", "r");


    float numero, soma = 0;
    float max, min;
    int contador = 0;

    while (fscanf(arquivo, "%f", &numero) == 1)
    {
        if (contador == 0)
        {
            max = min = numero;
        }
        else
        {
            if (numero > max)
                max = numero;
            if (numero < min)
                min = numero;
        }

        soma += numero;
        contador++;
    }

    fclose(arquivo);

    if (contador > 0)
    {
        float media = soma / contador;
        printf("%.2f\n", max);
        printf("%.2f\n", min);
        printf("%.2f\n", media);
        printf("%d\n", contador);
    }

    return 0;
}
