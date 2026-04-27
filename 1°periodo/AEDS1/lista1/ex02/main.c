#include <stdio.h>
#include <stdlib.h>

int main()
{

    float media,nota1,nota2,nota3,nota4;
    //printf("Digite as suas 4 notas");
    scanf("%f%f%f%f",&nota1,&nota2,&nota3,&nota4);

    media = (nota1 + nota2 + nota3 + nota4)/4;

    if(media >=7)
    {
        printf("%.2f\nAprovado", media);
    }
    else
    {
        printf("%.2f\nReprovado", media);
    }


    return 0;
}
