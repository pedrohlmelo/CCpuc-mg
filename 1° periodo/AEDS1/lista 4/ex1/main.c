#include <stdio.h>
#include <stdlib.h>

int ExibeDigitos(int n)
{
    if(n<10)
        return 1;
    else if(n>10)
        return 1+ExibeDigitos(n/10);
}

int main()
{
    int N;
    //printf("Digite o numero: ");
    scanf("%d",&N);

    printf("%d",ExibeDigitos(N));
    return 0;
}
