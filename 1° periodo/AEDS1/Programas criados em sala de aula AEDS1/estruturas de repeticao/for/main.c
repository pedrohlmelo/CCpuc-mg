#include <stdio.h>
#include <stdlib.h>

int main()
{
   int N,conta;
   float num, soma=0;
   printf("Digite a quantidade de numeros ");
   scanf("%d",&N);

   for (conta=0;conta<N;conta++)
   {
       printf("Digite um numero ");
       scanf("%f",&num);
       soma+=num;
   }
   if(conta>0)
   {
       printf("A media eh %.2f ",soma/conta);
   }
    return 0;
}
