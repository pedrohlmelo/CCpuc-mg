#include <stdio.h>
#include <stdlib.h>

int main()
{
    int L;
    int a = 1, b = 1, c;


    //printf("Digite o valor de L");
    scanf("%d", &L);


    if (L > 1)
{
    printf("1 ");
    }


    if (L > 1)
{
    printf("1 ");
    }


    while (1)
{
    c = a + b;
    if (c >= L)
        {
            break;
        }
        printf("%d ", c);
        a = b;
        b = c;
    }


    return 0;
}
