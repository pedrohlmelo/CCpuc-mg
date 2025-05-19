#include <stdio.h>
#include <stdlib.h>

int main()
{
    int N, positivo=0,negativo=0,zero=0,S;
    long int num;

    //printf("Digite a quantidade ");
    scanf("%d",&N);
    //printf("Digite os numeros ");


    for(S=0;S<N;S++)
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
      printf("%d POSITIVOS\n%d NEGATIVOS\n%d ZEROS\n",positivo,negativo,zero);

    return 0;
}
