#include <stdio.h>
#include <stdlib.h>

int main()
{
    int L, i;
    int fib1 = 1, fib2 = 1, nextFib;


    //printf("Digite o número L");
    scanf("%d", &L);


    for (i = 1; i <= L; i++)
    {
        if (i == 1)
        {
            printf("%d ", fib1);
        }
        else if (i == 2)
        {
            printf("%d ", fib2);
        }
        else
        {
            nextFib = fib1 + fib2;
            printf("%d ", nextFib);
            fib1 = fib2;
            fib2 = nextFib;
        }
    }


    return 0;
}
