#include <stdio.h>
int soma(int v[], int n) {
    int s = 0;
    for (int i = 0; i < n; i++)
        s += v[i];
    return s;
}
void main()
{       
    int v[5]={5,4,3,2,1};
    int n=5;
    int s=soma(v,n);
    printf("A soma dos %d termos é %d.",n,s);
}

