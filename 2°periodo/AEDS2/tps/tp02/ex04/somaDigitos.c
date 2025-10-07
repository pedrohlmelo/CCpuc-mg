#include <stdio.h>
#include <string.h>

int somaDigitos(char numero[], int i)
{
    if (numero[i] == '\0')//caso base
    {
        return 0;
    }
    if (numero[i] >= '0' && numero[i] <= '9')//conferir se e digito
    {
        return (numero[i] - '0') + somaDigitos(numero, i + 1);


    }


}

int main()
{
    char numero[50];

    scanf(" %[^\n]", numero);

    while (strcmp(numero, "FIM") != 0)
    {
        int soma = somaDigitos(numero, 0);
        printf("%d\n", soma);
        scanf(" %[^\n]", numero);
    }

    return 0;
}
