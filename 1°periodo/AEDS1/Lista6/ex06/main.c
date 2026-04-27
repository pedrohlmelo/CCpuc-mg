#include <stdio.h>
#include <stdlib.h>

int main()
{
    int matriz[4][4];
    int soma =0;
    for(int i=0;i<4;i++)
    {
        for(int j=0;j<4;j++)
        {
            scanf("%d",&matriz[i][j]);
        }

    }

    for(int i=0;i<4;i++)
    {
        for(int j=0;j<4;j++)
        {
            if(i>j)
            {
                soma+=matriz[i][j];
            }
        }
    }
    printf("%d\n",soma);


    for(int i=0;i<4;i++)
    {
        printf("%d ",matriz[i][i]);
    }
    return 0;
}
