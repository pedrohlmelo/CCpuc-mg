#include <stdio.h>
#include <stdlib.h>
int SomaDigitos(int n)
{

    if(n == 0)
        return 0;
    else if(n>10)
        return (n % 10) + (SomaDigitos(n/10));



}

int main()
{
    int numero;
    //printf("Digite o numero: ");
    scanf("%d",&numero);

    printf("%d",SomaDigitos(numero));


    return 0;
}
