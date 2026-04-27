#include <stdio.h>
#include <stdlib.h>

int main()
{
    int consoante = 0;
    int vogal = 0;
    char *vetor = (char*)malloc(100*sizeof(char));
    scanf(" %[^\n]",vetor);

     int tamanho = 0;
    while(vetor[tamanho] != '\0')
    {
        tamanho++;
    }

    for(int i =0; i<tamanho; i++)
    {
        if(vetor[i] == 'A' || vetor[i] =='E' ||  vetor[i] == 'I' ||  vetor[i] == 'O' || vetor[i] =='U')
        {
            vogal++;
        }
        else if(vetor[i] == 'a' || vetor[i] =='e' ||  vetor[i] == 'i' ||  vetor[i] == 'o' || vetor[i] =='u')
     {
        vogal++;
     }
    else
    {
        consoante++;
    }
}

printf("Vogais: %d\nConsoantes: %d",vogal,consoante);


    free(vetor);


    return 0;
}
