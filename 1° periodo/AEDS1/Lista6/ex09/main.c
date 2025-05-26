#include <stdio.h>
#include <stdlib.h>
void troca(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

int main()
{
    int N;
    scanf("%d",&N);

    int *vetor=(int*)malloc(N*sizeof(int));

    for(int i=0; i<N; i++)
    {
        scanf("%d",(vetor+i));
    }


    for (int i = 0; i < N - 1; i++)
    {
        for (int j = 0; j < N - i - 1; j++)
        {
            if (*(vetor + j) > *(vetor + j + 1))

            {
                troca((vetor + j), (vetor + j + 1));
            }
        }

    }

    for(int i=0; i<N; i++)
    {

        printf("%d ",*(vetor+i));
    }

    free(vetor);
    return 0;
}
