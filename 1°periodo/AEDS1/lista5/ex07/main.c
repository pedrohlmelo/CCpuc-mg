#include <stdio.h>
#include <stdlib.h>

int main()
{
    int N,contagem=0;
    char letras [200];
    FILE *saida = fopen("saida.txt","w");
    scanf("%d",&N);
    for(int i=0;i<N;i++)
    {
        scanf(" %c",&letras[i]);
        fprintf(saida, "%c\n",letras[i]);
        if(letras[i] == 'a' || letras[i] == 'e' || letras[i] == 'i' || letras[i] == 'o' || letras[i] == 'u')
        {
            contagem++;
        }
        else if(letras[i] == 'A' || letras[i] == 'E' || letras[i] == 'I' || letras[i] == 'O' || letras[i] == 'U')
        {
            contagem++;
        }
    }

    printf("%d\n",contagem);
    fclose(saida);

    return 0;
}
