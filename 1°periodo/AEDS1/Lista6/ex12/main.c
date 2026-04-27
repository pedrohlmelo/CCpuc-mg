#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void troca(char *a, char *b)
{
    char temp = *a;
    *a = *b;
    *b = temp;
}

void permutacoes(char *vetor, int inicio, int fim)
{
    if (inicio == fim)
    {
        printf("%s ", vetor);
    }
    else
    {
        for (int i = inicio; i <= fim; i++)
        {
            troca((vetor + inicio), (vetor + i));
            permutacoes(vetor, inicio + 1, fim);
            troca((vetor + inicio), (vetor + i));
        }
    }
}

int main()
{
    char *vetor;
    vetor = (char*)malloc(100 * sizeof(char));
    scanf("%s", vetor);
    int tamanho = strlen(vetor);
    printf("As permutações da string são:\n");
    permutacoes(vetor, 0, tamanho - 1);
    printf("\n");
    free(vetor);
    return 0;
}
