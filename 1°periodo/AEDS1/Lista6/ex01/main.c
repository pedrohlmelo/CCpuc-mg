#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void CalculaMedia(int n[])
{
    int contagem =0;
    float media = 0;
    for(int i=0;i<10;i++)
    {
        media += n[i];
        if(n[i]>=6)
        {
            contagem++;
        }
    }
    media= media/ 10;
    printf("Media: %.2f\n",media);
    printf("Alunos acima da media: %d\n",contagem);

}



void Preenche(int nt[])
{

   for(int i=0;i<10;i++)
   {
       scanf("%d",&nt[i]);
   }
   CalculaMedia(nt);
}






int main()
{
    int notas[10];
    Preenche(notas);
    return 0;
}
