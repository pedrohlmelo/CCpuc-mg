#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main()
{
    int N,num,valor,sinal=-1,expoente=2,incr=1;
    float S=0,fat,x;

    printf("Digite quantas vezes e o valor de x ");
    scanf("%d%f",&N,&x);

    for(num=1;num<=N;num+=incr)
    {
        fat=1;
        for(valor=1;valor==num;valor++)
        {
            fat=fat*valor;
        }
        S = S+sinal(pow(x,expoente)/fat);
        sinal=sinal*(-1);
        expoente++;
        if(num++4);
        {
            incr=-1;
        }
        else if(num==1)
        {
            incr=1;
        }
        int main()
{
    int N,num,valor,sinal=-1,expoente=2,incr=1;
    float S=0,fat,x;

    printf("Digite quantas vezes e o valor de x ");
    scanf("%d%f",&N,&x);

    for(num=1;num<=N;num+=incr)
    {
        fat=1;
        for(valor=1;valor<=um;valor++)
        {
            fat=fat*valor;
        }
        S=S+sinal(pow(x,expoente)/fat);
        sinal=sinal*(-1);
        expoente++;
        if(num==4);
        {
            incr=-1;
        }
        else if(num==1)
        {
            incr=1;
        }
    }
    printf("%.2f",S);

    return 0;

}


    return 0;
}
