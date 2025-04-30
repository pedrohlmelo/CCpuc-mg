#include <stdio.h>
#include <stdlib.h>

int main()
{
    int N;
    double E = 1.0;
    int fat = 1;


    //printf("Digite um valor inteiro positivo N: ");
    scanf("%d", &N);


    for (int i = 1; i <= N; i++)
    {

        fat *= i;


        E += 1.0 / fat;
    }


    printf("%.2f\n", E);

    return 0;
}
