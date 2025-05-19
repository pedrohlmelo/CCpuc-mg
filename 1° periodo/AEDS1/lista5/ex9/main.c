#include <stdio.h>
#include <stdlib.h>

int main()
{
    int opcao, matricula, telefone,quantidade;
    FILE *entrada,*saida;



    printf("Digite a quantidade de alunos ");
    scanf("%d",&quantidade);

    printf("Digite a opcao ");
    scanf("%d",&opcao);

    printf("Digite os dados\n");



    if(opcao == 1)
    {
        entrada = fopen("entrada.txt","w");
        for(int i=1;i<=quantidade;i++)
        {
            scanf("%d%d",&matricula,&telefone);
            fprintf(entrada,"%d %d\n",matricula,telefone);
        }
    }

    else if(opcao == 2)
    {
        saida = fopen("saida.txt","w");
        for(int i=1;i<=quantidade;i++)
        {
            scanf("%d%d",&matricula,&telefone);
            fprintf(saida,"%d %d\n",matricula,telefone);
        }
    }


    fclose(entrada);
    fclose(saida);

    return 0;
}
