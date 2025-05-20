#include <stdio.h>
#include <stdlib.h>

void conceitoAluno(int nota)
{
    if(nota<=39)
    {
        printf("F\n");
    }
    else if(40<=nota && nota<=59)
    {
        printf("E\n");
    }
    else if(60<=nota && nota<=69)
    {
        printf("D\n");
    }
    else if(70<=nota && nota<=79)
    {
        printf("C\n");
    }
    else if(80<=nota && nota<=89)
    {
        printf("B\n");
    }
    else if(nota>=90)
    {
        printf("A\n");
    }

}

int main()
{
    int n,avaliacao;
    //printf("Digite a quantidade de alunos\n");
    scanf("%d",&n);

    //printf("Digite as notas dos alunos\n");
    for(int u=0; u<n; u++)
    {
    scanf("%d",&avaliacao);

    conceitoAluno(avaliacao);

    }

    return 0;
}
