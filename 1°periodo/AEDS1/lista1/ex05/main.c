#include <stdio.h>
#include <stdlib.h>

int main()
{
    float salario, nsalario;
    //printf("digite o seu salario atual");
    scanf("%f",&salario);
    nsalario = (salario * 0.3) + salario;
    if(salario<500)
    {
        printf("%.2f",nsalario);
    }
    else
    {
        printf("Sem reajuste");
    }
    return 0;
}
