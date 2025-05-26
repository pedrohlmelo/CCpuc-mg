#include <stdio.h>


void preencheMatriz(int m[5][5])
{
    for (int i = 0; i < 5; i++)
    {
        for (int j = 0; j < 5; j++)
        {
            scanf("%d", &m[i][j]);
        }
    }
}




int linha4(int m[5][5])
{
    int soma = 0;
    for (int j = 0; j < 5; j++)
    {
        soma += m[4][j];
    }

    return soma;
}


int coluna2(int m[5][5])
{
    int soma = 0;
    for (int i = 0; i < 5; i++)
    {
        soma += m[i][2];
    }

    return soma;
}


int diagonalPrincipal(int m[5][5])
{
    int soma = 0;
    for (int i = 0; i < 5; i++)
    {
        soma += m[i][i];
    }

    return soma;
}


int diagonalSecundaria(int m[5][5])
{
    int soma = 0;
    for (int i = 0; i < 5; i++)
    {
        soma += m[i][4 - i];
    }

    return soma;
}


int somaElementos(int m[5][5])
{
    int soma = 0;
    for (int i = 0; i < 5; i++)
    {
        for (int j = 0; j < 5; j++)
        {
            soma += m[i][j];
        }

    }

    return soma;
}

int main()
{
    int matriz[5][5];


    preencheMatriz(matriz);


    printf("%d\n", linha4(matriz));
    printf("%d\n", coluna2(matriz));
    printf("%d\n", diagonalPrincipal(matriz));
    printf("%d\n", diagonalSecundaria(matriz));
    printf("%d\n", somaElementos(matriz));

    return 0;
}
