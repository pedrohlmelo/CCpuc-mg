#include <stdio.h>
#include <stdlib.h>

int main()
{
    float salariomin, preco, npreco, kilowattgasto, pkilowatt;



    printf("digite o salario minimo no seu pais atualmente");
    scanf("%f", &salariomin);

    printf("digite quantos kilowatts foram gastos");
    scanf("%f", &kilowattgasto);

    pkilowatt= salariomin /7 /100;

    preco= kilowattgasto * pkilowatt;

    npreco = preco - (preco * 10/100);

    printf("valor de cada kilowatt %.2f\n", pkilowatt);
    printf("preco total %.2f\n", preco);
    printf("preco com desconto %.2f\n", npreco);

    return 0;

}
