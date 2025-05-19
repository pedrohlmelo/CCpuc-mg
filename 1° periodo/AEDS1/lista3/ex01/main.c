#include <stdio.h>
#include <stdlib.h>

void calculoMedia(int alunos, int n1, int n2, int n3, char letra)
{
    float media;


    if(letra =='A')
    {
        media = (n1+n2+n3)/3.0;

    }
    else if(letra =='P')
    {
        media =(n1*5+n2*3+n3*2)/10.0;

    }
    printf("%.2f\n", media);



}




int main()
{
    float nota1,nota2,nota3;
    int N,i;
    char L;
    //printf("Digite aquantidade de alunos");
    scanf("%d",&N);

    //printf("Digite as notas e o tipo de media\n");

    for(i=0; i<N; i++)
    {

        scanf("%f%f%f %c",&nota1,&nota2,&nota3,&L);
        calculoMedia(N,nota1,nota2,nota3,L);


    }


    return 0;
}
