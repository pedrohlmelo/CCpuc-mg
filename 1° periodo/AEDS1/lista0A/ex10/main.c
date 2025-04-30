#include <stdio.h>
#include <stdlib.h>

int main()
{
    int horas, minutos, tempototal;
    printf("digite quantas horas se passaram no dia de hoje");
    scanf("%d",&horas);

    printf("digite a quantidade de minutos que acompanham o horario atual");
    scanf("%d",&minutos);

    tempototal = horas * 60 + minutos;

    printf("se passaram %d minutos desde o inicio do dia", tempototal);

    return 0;
}
