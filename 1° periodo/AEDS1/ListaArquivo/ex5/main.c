#include <stdio.h>
#include <stdlib.h>

void copiarConteudo(FILE *origem, FILE *destino)
{
    char linha[1000];
    while (fgets(linha, sizeof(linha), origem) != NULL)
    {
        fputs(linha, destino);
    }
}

int main()
{
    FILE *arq1, *arq2, *saida;

    arq1 = fopen("arquivo1.txt", "r");
    arq2 = fopen("arquivo2.txt", "r");
    saida = fopen("saida.txt", "w");



    copiarConteudo(arq1, saida);
    copiarConteudo(arq2, saida);



    fclose(arq1);
    fclose(arq2);
    fclose(saida);

    return 0;
}
