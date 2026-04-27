#include <stdio.h>
#include <stdlib.h>

int main()
{
    FILE *saida = fopen("saida.txt","w");
    for(int i=1;i<11;i++)
    {
        fprintf(saida,"%d\n",i);
    }
    fclose(saida);
    return 0;
}
