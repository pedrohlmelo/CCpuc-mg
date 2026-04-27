#include <stdio.h>
#include <stdlib.h>

float calculaMediaAprovados(int N)
{
    float nota, somaNotas = 0.0;
    int contAprovados = 0;

    //printf("Digite as notas dos alunos:\n");
    for (int i = 0; i < N; i++)
    {
        scanf("%f", &nota);
        if (nota >= 6.0)
        {
            somaNotas += nota;
            contAprovados++;
        }
    }



    return somaNotas / contAprovados;
}

int main()
{
    int N;

   //printf("Digite o número de alunos: ");
    scanf("%d", &N);



    printf("%.1f\n", calculaMediaAprovados(N));

    return 0;
}
