#include <stdio.h>
#include <stdlib.h>

void processaTurma(int total)
{
    float soma =0, menor =101, maior =-1, conta=0;
    float nota;
    for(int num =1; num<=total;num++)
    {
        printf("Nota: ");
        scanf("%f",&nota);
        soma+=nota;
        if(nota<menor)
        {
            menor = nota;
        }
        if(nota>maior)
        {
            maior = nota;
        }
        if(nota>=60)
        {
            conta++;
        }
        //printf...
    }
}


int main()
{
    int N;
    printf("Quantos alunos tem na turma: ");
    scanf("%d",&N);
    processaTurma(N);
    return 0;
}
