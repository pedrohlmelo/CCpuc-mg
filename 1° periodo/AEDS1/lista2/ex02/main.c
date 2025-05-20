#include <stdio.h>
#include <stdlib.h>

int main()
{
    int N, positivo=0,negativo=0,zero=0,S;
    float pp,pn,pz;
    long int num;

    //printf("Digite a quantidade ");
    scanf("%d",&N);
    //printf("Digite os numeros ");


    for(S=0; S<N; S++)
    {
        scanf("%ld",&num);
        if(num>0)
        {
            positivo++;
        }
        else if(num<0)
        {
            negativo++;
        }
        else
        {
            zero++;
        }

    }
    pp = ((float)positivo/N)*100;
    pn = ((float)negativo/N)*100;
    pz = ((float)zero/N)*100;
    printf("%.0f%% POSITIVOS\n%.0f%% NEGATIVOS\n%.0f%% ZEROS\n",pp,pn,pz);

    return 0;
}
