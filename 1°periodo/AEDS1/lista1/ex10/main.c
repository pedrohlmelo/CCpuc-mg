#include <stdio.h>

int main()
{
    int horas_extras, horas_falta;
    float H, premio;


    //printf("Digite o numero de horas extras: ");
    scanf("%d", &horas_extras);
    //printf("Digite o numero de horas de falta: ");
    scanf("%d", &horas_falta);


    H = horas_extras - (2.0 / 3.0) * horas_falta;


    if (H >= 40)
    {
        premio = 500.00;
    }
    else if (H > 30 && H < 40)
    {
        premio = 400.00;
        printf("%.2f\n", premio);
    }
    else if (H >= 20 && H < 30)
    {
        premio = 300.00;
        printf("%.2f\n", premio);
    }
    else if (H >= 10 && H < 20)
    {
        premio = 200.00;
        printf("%.2f\n", premio);
    }
    else
    {
        premio = 100.00;
        printf("%.2f\n", premio);
    }


}



