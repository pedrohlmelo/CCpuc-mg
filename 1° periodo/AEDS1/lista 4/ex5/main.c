#include <stdio.h>
#include <stdlib.h>

double serie(int n) {
    if (n == 1)
        return 1.0;
    else
    {
        double fat = 1.0;
        for (int i = 1; i <= n; i++)
        {
            fat *= i;
        }
        return (1.0 / fat) + serie(n - 1);
    }
}

int main()
{
    int N;
    //printf("Digite o numero de parcelas ");
    scanf("%d",&N);

    printf("%.2lf",serie(N));
    return 0;
}
