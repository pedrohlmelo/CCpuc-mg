#include <stdio.h>
#include <stdlib.h>

int main()
{
    char texto[200];
    FILE *arquivo = fopen("arquivoExemplo.txt","w");

    scanf(" %[^\n]", texto);

    fprintf(arquivo,"%s",texto);


    fclose(arquivo);
    return 0;
}
