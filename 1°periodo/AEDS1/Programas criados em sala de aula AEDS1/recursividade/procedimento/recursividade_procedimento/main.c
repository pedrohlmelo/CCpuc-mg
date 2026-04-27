#include <stdio.h>
#include <stdlib.h>

void escreveSequencia(int num)
{
    if(num == 1)
        printf("1");
    else if(num>1)
    {
        escreveSequencia(num-1);
        printf("%d",num);

    }
    else
        printf("Numero invalido");
        printf("\n");


}

int main()
{
    int N;
    scanf("%d",&N);
    escreveSequencia(N);
    return 0;
}
