#include <stdio.h>
#include <stdlib.h>

int main()
{
    char texto[200];
    int contagem =0;
    FILE *arquivo = fopen("arquivoExemplo.txt","w");

    scanf(" %[^\n]", texto);

    fprintf(arquivo,"%s",texto);

    fclose(arquivo);

    arquivo = fopen("arquivoExemplo.txt","r");

    fscanf(arquivo," %[^\n]", texto);

    for(int i=0;texto[i] != '\0';i++)
    {
        if(texto[i] == 'a')
        {
            contagem++;
        }
    }




    printf("%d CARACTERES",contagem);



    fclose(arquivo);
    return 0;
}

