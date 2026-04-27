#include <stdio.h>
#include <stdlib.h>


int main()
{
    float raio, perimetro, area, PI;
    PI = 3.14159;

    printf("escreva o valor do raio do circulo\n");
    scanf("%f", &raio);

    perimetro = 2 * PI *raio ;
    area = PI * raio * raio;

    printf("perimetro:%.2f\n", perimetro);
    printf("area:%.2f\n", area);



    return 0;
}
