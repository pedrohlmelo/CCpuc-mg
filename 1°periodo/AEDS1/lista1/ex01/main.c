#include <stdio.h>
#include <stdlib.h>

int main()
{
    int a,b,c;
    //printf("Digite 3 numeros");
    scanf("%d%d%d",&a,&b,&c);
    if(a>b && b>c)
    {
        printf("%d",a);
    }
    else if (b>a && a>c)
    {
        printf("%d",b);
    }
    else
    {
        printf("%d",c);
    }

    return 0;
}
