#include <stdio.h>
#include <stdlib.h>

int main()
{

    float salario, total_salarios = 0, media_salario;
    int filhos, total_filhos = 0, contador_pessoas = 0;
    float maior_salario = -1;
    int contador_salario_ate_100 = 0;
    float percentual_salario_ate_100;
    //printf("Informe o salário e o número de filhos\n ");


    while (1)
    {


        scanf("%f%d", &salario, &filhos);


        if (salario == -1)
        {
            break;
        }

        total_salarios += salario;
        total_filhos += filhos;
        contador_pessoas++;


        if (salario > maior_salario)
        {
            maior_salario = salario;
        }


        if (salario <= 100)
        {
            contador_salario_ate_100++;
        }
    }


    if (contador_pessoas > 0)
    {
        media_salario = total_salarios / contador_pessoas;
        percentual_salario_ate_100 = (contador_salario_ate_100 / (float)contador_pessoas) * 100;
        printf("%.2f\n%d\n%.2f\n%.2f",media_salario,total_filhos /contador_pessoas,maior_salario,percentual_salario_ate_100);



    }

    return 0;


}
