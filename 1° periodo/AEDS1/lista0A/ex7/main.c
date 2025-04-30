#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main()
{
    int razao, pg1, pg5;

    printf("escreva a razao da pg");
    scanf("%d", &razao);

    printf("escreva o primeiro termo da pg");
    scanf("%d", &pg1);

    pg5 = pg1 * pow(razao,4);

    printf("quinto termo da pg = %d", pg5);
    return 0;
}
