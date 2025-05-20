#include <stdio.h>
#include <stdlib.h>


int main()
{
    float valor, valormes;
    char resposta;
    //printf("digite o valor para aportes no investimento");
    scanf("%f",&valor);

    //printf("Escolha o tipo de investimento, Poupanca(P) ou Fundos de renda rixa(F)");
    scanf(" %c",&resposta);

    if(resposta == 'P')
    {
        valormes = valor + (valor*0.03);
        printf("%.2f",valormes);
    }
    else if (resposta == 'F')
    {
        valormes = valor + (valor*0.04);
        printf("%.2f",valormes);
    }
    return 0;
}
