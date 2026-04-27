#include <stdio.h>
#include <stdlib.h>

void converteHora(int totalsegundos, int *hora, int *min, int *seg)
{
     if (totalsegundos >= 3600)
     {
        *hora = totalsegundos/3600;
        totalsegundos = totalsegundos % 3600;

        if(totalsegundos % 3600 >60)
            *min = totalsegundos / 60;
            totalsegundos = totalsegundos %60;
        if(totalsegundos % 60 >0)
        {
            *seg = totalsegundos;
        }
     }
     else if (totalsegundos < 3600)
     {
         *hora = 0;
         *min = totalsegundos/60;
         *seg = totalsegundos % 60;
     }
}

int main()
{
    int *hora = (int*)malloc(sizeof(int));
    int *minuto = (int*)malloc(sizeof(int));
    int *segundo = (int*)malloc(sizeof(int));

    int totalseg;

    //printf("Digite o total de segundos");
    scanf("%d",&totalseg);

    converteHora(totalseg,hora,minuto,segundo);
     printf("%d:%d:%d",*hora,*minuto,*segundo);

     free(hora);
     free(minuto);
     free(segundo);
    return 0;
}
