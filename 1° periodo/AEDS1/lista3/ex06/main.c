#include <stdio.h>
#include <stdlib.h>
float calculaS(int N)
{
    float S=1.0;
    int fat=1;
    for(int i=1;i<=N;i++)
    {
        fat*=i;
        S+=1.0/fat;
    }
    return S;

}
int main()
{
    int n;
    //printf("Digite a quantidade de parcelas\n");
    scanf("%d",&n);

    printf("%f",calculaS(n));
    return 0;
}
