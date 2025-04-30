#include <stdio.h>
#include <stdlib.h>




double calcularS(int N)
{
    double S = 0.0;
    for (int i = 1; i <= N; i++)
    {
        S += (double)((i * i) + 1) / (i + 3);
    }
    return S;
}

int main()
{
    int N;
    scanf("%d", &N);
    printf("%lf\n", calcularS(N));
    return 0;
}
