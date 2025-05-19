#include <stdio.h>
#include <stdlib.h>

int main()
{
    float A,B, inversao;
    printf("escreva 2 valores diferentes\n");
    scanf("%f%f",&A,&B);

    inversao = A;
    A =  B;
    B = inversao;

    printf("inversao, %.2f,%.2f\n", A,B);
    return 0;
}
