#include <stdio.h>
#include <stdlib.h>

int main()
{
    float consumoKml;
    float capacidadeTanque;
    int distancia;
    float autonomiaTotal;


    srand(6);
    distancia = rand() % 101;
    scanf("%f", &consumoKml);
    scanf("%f", &capacidadeTanque);
    autonomiaTotal = consumoKml * capacidadeTanque;
    if (distancia <= autonomiaTotal)
    {

        printf("A moto não precisa parar para abastecer\n");
    }
    else
    {

        int paradas = distancia / (int)autonomiaTotal;

        if (distancia % (int)autonomiaTotal == 0)
        {
            paradas--;
        }

        printf("A moto precisa parar %d vezes para abastecer\n", paradas);
    }

    return 0;
}
