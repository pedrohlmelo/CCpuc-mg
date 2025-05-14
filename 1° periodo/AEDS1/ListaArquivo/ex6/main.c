#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n,soma=0;
    int num[200];

    printf("Digite um numero ");
    scanf("%d",&n);

    for(int i = 1;i <= n; i++)
    {
        if(n % i == 0)
        {
            num[i] = i;
            soma+= num[i];
            printf("%d\n",num[i]);
        }
    }

    FILE *saida = fopen("saida.txt","w");
    fprintf(saida,"%d",soma);
    fclose(saida);
    return 0;
}
