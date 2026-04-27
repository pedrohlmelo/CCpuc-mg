#include <stdio.h>
#include <stdlib.h>

int main()
{
    int temperatura [31];
    int menor=40, maior=0;
    float tempmedia = 0;
    int contagem =0;
    int contagem_validas = 0;

    for(int i =0; i<31; i++)
    {
        scanf("%d",&temperatura[i]);
        if(temperatura[i]> maior)
        {
            maior = temperatura[i];
        }
        if(temperatura[i]<menor)
        {
            menor=temperatura[i];
        }
        if (15<=temperatura[i] && temperatura[i]<=40 )
        {
            tempmedia+=temperatura[i];
            contagem_validas++;
        }
    }
    tempmedia =(tempmedia/contagem_validas);

    for(int i =0; i<31; i++)
    {
        if(temperatura[i]<tempmedia)
        {
            contagem++;
        }
    }


    printf("Menor e maior temperatura: %d e %d\n",menor,maior);
    printf("Media de temperatura: %.2f\n",tempmedia);
    printf("Numero de dias nos quais a temperatura foi inferior a temperatura media: %d\n",contagem);
    return 0;
}
