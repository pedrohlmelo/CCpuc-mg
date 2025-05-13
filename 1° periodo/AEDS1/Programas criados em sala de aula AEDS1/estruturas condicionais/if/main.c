#include <stdio.h>
#include <stdlib.h>

int main()
{
    int lado1,lado2,lado3;
    printf("digite os 3 lados ");
    scanf("%d%d%d",&lado1,&lado2,&lado3);

    if( lado1 == lado2 && lado2 == lado3)

    {
        printf("triangulo equilatero");
    }
    else if( lado1 == lado2 || lado1 == lado3 || lado2 == lado3)
    {
        printf("triangulo isoceles");
    }
    else
    {
        printf("triangulo escaleno");
    }
    return 0;
}
