#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

bool verificaPositivo(int num)
{
    if (num > 0)
    {
        return true;
    }
    else
    {
        return false;
    }
}

int main()
{
    int N, num;

    //printf("Digite a quantidade de números a serem lidos\n");
    scanf("%d", &N);

    //printf("Digite um numero\n");

    for (int i = 0; i < N; i++)
    {

        scanf("%d", &num);

        if (verificaPositivo(num))
        {
            printf("SIM\n");
        }
        else
        {
            printf("NAO\n");
        }
    }

    return 0;
}
