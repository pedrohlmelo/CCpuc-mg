#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n;
    scanf("%d",&n);
    int maior =0;

    int *vetor = (int*)malloc(n*sizeof(int));

    for(int i=0;i<n;i++)
    {
        scanf("%d",(vetor+i));
        if(*(vetor+i)>maior)
        {
            maior = *(vetor+i);
        }
    }
    printf("%d",maior);
    free(vetor);
    return 0;
}
