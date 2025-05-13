#include <stdio.h>
#include <stdlib.h>

void soma(int *a)
{
    printf("%d\n",*a);
    *a=*a+5;
    printf("%d\n",*a);
}

int main()
{
    int num;
    printf("Digite : ");
    scanf("%d",&num);
    soma(&num);
    printf("%d\n",num);
    return 0;
}
