#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n;
    scanf("%d",&n);

    char *vetor = (char*)malloc(n*sizeof(char));

    scanf(" %[^\n]",vetor);


     for(int i=n-1;i>=0;i--)
    {
        printf("%c",*(vetor+i));
    }

    free(vetor);
    return 0;
}
