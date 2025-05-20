#include <stdio.h>
#include <stdlib.h>

int main()
{
    int n;
    float preco,faturamento,nalugados;
    float multas,manutencao;
    scanf("%d%f",&n,&preco);

    nalugados = 1.0/3.0*n;
    faturamento = nalugados*preco*12.0;
    multas = nalugados*1.0/10.0*preco*0.2;
    manutencao = (n*2.0/100.0)*(600.00);

    printf("%.2f\n%.2f\n%.2f",faturamento,multas,manutencao);


    FILE *saida = fopen("saida.txt","w");
    fprintf(saida,"%.2f\n%.2f\n%.2f",faturamento,multas,manutencao);
    fclose(saida);


    return 0;
}
