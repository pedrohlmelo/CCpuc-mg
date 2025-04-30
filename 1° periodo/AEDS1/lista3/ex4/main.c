#include <stdio.h>
#include <stdlib.h>

void tipoTriangulo(int X, int Y, int Z)
{


    if(X+Y>Z && X+Z>Y && Z+Y>X)
    {
        if(X==Y && Y==Z)
        {
            printf("TRIANGULO EQUILATERO\n");
        }
        else if(X==Y || Y==Z || X==Z)
        {
            printf("TRIANGULO ISOSCELES\n");
        }
        else if(X!=Z && Z!=Y && X!= Y)
        {
            printf("TRIANGULO ESCALENO\n");
        }

    }
    else
        {
            printf("NAO TRIANGULO\n");
        }


}

int main()
{
    int x,y,z;
    //printf("Digite os lados do triangulo\n");
    while(1)
    {
        scanf("%d%d%d",&x,&y,&z);
        if(x==-1)
        {
            break;
        }
        tipoTriangulo(x,y,z);
    }
    return 0;
}
