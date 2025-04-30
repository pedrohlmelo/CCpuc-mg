#include <stdio.h>

int main()
{
    int anon, idade, anoa;
    char resposta;


    //printf("Digite em qual ano voce nasceu: ");
    scanf("%d", &anon);


    //printf("Digite o ano atual: ");
    scanf("%d", &anoa);


    idade = anoa - anon;


    //printf("Voce ja fez aniversario esse ano (S ou N): ");
    scanf(" %c", &resposta);

    if (resposta == 'S')
    {

        if (idade >= 18)
        {
            printf("%d\nPode dirigir",idade);
        }
        else
        {
            printf("%d\nNao pode dirigir",idade);
        }
    }
    else if (resposta == 'N')
    {

        if (idade  > 18)
        {
            printf("%d\nPode dirigir",idade-1);
        }
        else
        {
            printf("%d\nNao pode dirigir",idade);
        }
    }

    return 0;
}
