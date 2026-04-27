#include <stdio.h>
#include <stdlib.h>

int main()
{
    FILE *arquivo = fopen("entrada.txt", "r");
    char linha[1000];
    int contador = 0;



    while (fgets(linha, sizeof(linha), arquivo) != NULL)
    {
        printf("%s", linha);
        contador++;
    }

    printf("%d LINHAS\n", contador);

    fclose(arquivo);
    return 0;
}
