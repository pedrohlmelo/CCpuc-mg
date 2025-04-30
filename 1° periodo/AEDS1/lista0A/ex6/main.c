#include <stdio.h>
#include <stdlib.h>

int main()
{
    int razao, pa1, pa10;

    printf("escreva a razao da PA");
    scanf("%d", &razao);

    printf("escreva o primeiro termo da PA");
    scanf("%d", &pa1);

    pa10 = pa1 + 9 * razao;

    printf("decimo termo da pa = %d", pa10);

    return 0;
}
