#include <stdio.h>
#include <stdlib.h>


int fatorial(int num)
{
    if(num == 0 || num == 1)
    {
        return 1;
    }
    else if(num>1)
        return(num*fatorial(num-1));
    else
        return -1;
}
int main()
{
    int N;
    scanf("%d",&N);

    printf("O fatorial de %d eh %d",N,fatorial(N));
    return 0;
}
