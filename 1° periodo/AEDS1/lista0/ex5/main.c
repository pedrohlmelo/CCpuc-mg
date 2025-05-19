#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main()
{
    float cateto1, cateto2, hipotenusa;

    printf("escreva o valor do primeiro e do segundo cateto, respectivamente");
    scanf("%f%f",&cateto1, &cateto2);

    hipotenusa = sqrt(pow(cateto1,2)+pow(cateto2,2));

    printf("valor da hipotenusa %.2f", hipotenusa);


    return 0;
}
