#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n;
    scanf("%d",&n);
    int soma =0;

    int *vetor = (int*)malloc(n*sizeof(int));

    for(int i =0; i<n; i++)
    {
        scanf("%d",(vetor+i));
        soma+=*(vetor+i);
    }

    printf("%d",soma);
    free(vetor);
    return 0;
}
