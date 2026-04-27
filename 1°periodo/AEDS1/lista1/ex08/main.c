#include <stdio.h>
#include <stdlib.h>

int main()
{
    float altura,pesoid;
    char resposta;
    //printf("Digite a sua altura");
    scanf("%f",&altura);

    //printf("digite se voce e homem(H) ou mulher(M)");
    scanf(" %c",&resposta);

    if(resposta == 'H')
    {
        pesoid = (72.7*altura)-58;
        printf("%.2f",pesoid);
    }
    else if (resposta == 'M')
    {
        pesoid = (62.1*altura)-44.7;
        printf("%.2f",pesoid);
    }


    return 0;
}
