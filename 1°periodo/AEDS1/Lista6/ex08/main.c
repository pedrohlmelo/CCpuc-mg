#include <stdio.h>
#include <stdlib.h>

void preenche(int matriz[10][10])
{
    for(int i=0; i<10; i++)
    {
        for(int j=0; j<10; j++)
        {
            scanf("%d",&matriz[i][j]);
        }
    }


}

void trocaLinha2(int matriz[10][10])
{
    int aux[10];
    for(int j=0; j<10; j++)
    {
        aux[j] = matriz[1][j];
        matriz[1][j] = matriz[7][j];
        matriz[7][j] = aux[j];
    }
}

void trocaColuna4(int matriz[10][10])
{
    int aux[10];
    for(int i=0; i<10; i++)
    {
        aux[i] = matriz[i][3];
        matriz[i][3] = matriz[i][9];
        matriz[i][9] = aux[i];
    }
}

void DprincipalDsecundaria(int matriz[10][10])
{
    int aux[10];
    for (int i=0; i<10; i++)
    {
        aux[i] = matriz[i][i];
    }

    for (int i = 0; i<10; i++)
    {
        matriz[i][i] = matriz[i][10 - 1 - i];
        matriz[i][10 - 1 - i] = aux[i];
    }
}

void Linha5(int matriz[10][10])
{
    int aux[10];
    for (int j=0; j<10; j++)
    {
        aux[j] = matriz[4][j];
        matriz[4][j] = matriz[j][9];
        matriz[j][9] = aux[j];
    }
}

void exibeMatriz(int matriz[10][10])
{
    for(int i=0; i<10; i++)
    {
        for(int j=0; j<10; j++)
        {
            printf("%d ", matriz[i][j]);
        }
        printf("\n");
    }
}

int main()
{
    int matriz[10][10];
    preenche(matriz);
    trocaLinha2(matriz);
    trocaColuna4(matriz);
    DprincipalDsecundaria(matriz);
    Linha5(matriz);
    exibeMatriz(matriz);
    return 0;
}
