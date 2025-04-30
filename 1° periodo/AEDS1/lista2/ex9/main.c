#include <stdio.h>
#include <stdlib.h>

int main()
{
    float compra,venda,lucro,totalcompra=0,totalvenda=0,lucrototal;
    int menor10=0,i1020=0,maior20=0;
    //printf("Digite o preco de compra e o de venda\n");
    while(1)
    {
        scanf("%f%f",&compra,&venda);

        if(compra == 0)
        {
            break;
        }
        totalcompra+=compra;
        totalvenda+=venda;
        lucrototal=totalvenda-totalcompra;
        lucro = venda-compra;

        if(lucro / compra < 0.10)
        {
            menor10++;
        }
        else if(lucro / compra >= 0.10 && lucro / compra <= 0.20)
        {
            i1020++;
        }
        else
        {
            maior20++;
        }

    }
    printf("%d\n%d\n%d\n%.2f\n%.2f\n%.2f",menor10,i1020,maior20,totalcompra,totalvenda,lucrototal);
    return 0;
}
