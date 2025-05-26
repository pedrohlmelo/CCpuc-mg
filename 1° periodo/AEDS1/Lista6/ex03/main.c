#include <stdio.h>
#include <stdlib.h>
void preenche (int X[], int Y[])
{
    for(int i=0; i<10; i++)
    {
        scanf("%d",&X[i]);
    }
    for(int i=0; i<10; i++)
    {
        scanf("%d",&Y[i]);
    }
    recebe(X,Y);
}

void recebe (int X[],int Y[])
{
    int Z[20];

    for(int i=0; i<10; i++)
    {

        Z[2*i]=X[i];
        Z[2*i+1]=Y[i];

    }

    exibe(Z);

}

void exibe(int u[])
{
    for(int i=0; i<20; i++)
    {
        printf("%d ",u[i]);
    }
}
int main()
{
    int x[10],y[10];

    preenche(x,y);




    return 0;
}
