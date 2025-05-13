#include <stdio.h>
#include <stdlib.h>

int main()
{
    int a,b;
    char operacao;

    printf("Digite 2 valores ");
    scanf("%d%d",&a,&b);

    printf("Escolha a operacao + - * / ");
    scanf(" %c",&operacao);

    switch(operacao)
    {
        case '+' : printf("Resultado %d",(a+b));
        break;
        case '-' : printf("Resultado %d",(a-b));
        break;
        case '*' : printf("Resultado %d",(a*b));
        break;
        case '/' :
        if(b!=0)
        {
            printf("Resultado %d",(a/b));
        }
        else
        {
            printf("ERRO - divisao por zero");
        }
        break;

        default : printf("operacao invalida");
        break;
    }






    return 0;
}
