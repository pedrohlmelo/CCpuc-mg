#include <stdio.h>
#include <stdlib.h>

int* matrizSoma(int a[4][6], int b[4][6])
{
    int *matrizS = (int*)malloc(4 * 6 * sizeof(int));

    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            *(matrizS + (i * 6) + j) = a[i][j] + b[i][j];
        }
    }

    return matrizS;
}

int* matrizSubtrai(int a[4][6], int b[4][6])
{
    int *matrizD = (int*)malloc(4 * 6 * sizeof(int));

    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            *(matrizD + (i * 6) + j) = a[i][j] - b[i][j];
        }
    }

    return matrizD;

}

void preenche()
{
    int a[4][6], b[4][6];


    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            scanf("%d", &a[i][j]);
        }
    }


    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            scanf("%d", &b[i][j]);
        }
    }

    int *Soma = matrizSoma(a, b);
    int *Subtracao = matrizSubtrai(a, b);


    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            printf("%d ", *(Soma + (i * 6) + j));
        }
    }




    for (int i = 0; i < 4; i++)
    {
        for (int j = 0; j < 6; j++)
        {
            printf("%d ", *(Subtracao + (i * 6) + j));
        }
    }

    free(Soma);
    free(Subtracao);


}

int main()
{
    preenche();
    return 0;
}
