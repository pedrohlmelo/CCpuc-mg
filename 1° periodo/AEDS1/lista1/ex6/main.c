#include <stdio.h>
#include <stdlib.h>

int main()
{
    float a,b,x;
    //printf("Digite os coeficientes da equacao");
    scanf("%f%f",&a,&b);

    if(a != 0)
    {
        x = -b / a;
        printf("%.2f",x);
    }
    else
    {
        printf("erro");
    }


    return 0;
}
