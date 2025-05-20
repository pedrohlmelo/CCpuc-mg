#include <stdio.h>
#include <stdlib.h>

int main()
{
    int N,i;
    float soma=0.0;

    //printf("Digite a quantidade");
    scanf("%d",&N);

    for(i=1; i<=N; i++)
    {
        soma+=1.0/i;
    }
    printf("%.2f",soma);

    return 0;
}
