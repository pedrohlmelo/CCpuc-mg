#include <stdio.h>
#include <stdlib.h>
#include <math.h>
int main()
{
    float base, altura, perimetro, area, diagonal;

    printf("digite o valor da base do retangulo\n");
    scanf("%f", &base);

    printf("digite o valor da altura do retangulo\n");
    scanf("%f", &altura);

    area = base * altura;
    perimetro = 2*base + 2*altura;
    diagonal = sqrt(base*base+altura*altura);

    printf("perimetro: %.2f\n", perimetro);
    printf("area: %.2f\n", area);
    printf("diagonal: %.2f\n", diagonal);

   return 0;
}
