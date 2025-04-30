#include <stdio.h>
#include <stdlib.h>
void mediaSalario(float salariototal,float ms,int u)
{


    ms=salariototal/u;
    printf("%.2f",ms);
}
int main()
{

    float S,MS=0.0,ST=0.0;
    int N=0,i=0;
    //printf("Digite o seu salario e o numero de filhos\n");
    while(1)
    {
        scanf("%f%d",&S,&N);
        if(S==-1)
            break;
        ST+=S;
        i++;
        MS=ST/i;

    }
    mediaSalario(ST,MS,i);





    return 0;


}
