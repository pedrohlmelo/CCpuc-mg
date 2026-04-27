#include <stdio.h>
#include <stdlib.h>

typedef struct
{
    float largura;
    float altura;
}Retangulo;

void Preenche(Retangulo*vet, int tam)
{
   for(int i=0;i<tam;i++)
   {
       scanf("%f",&((vet+i)->largura));
       scanf("%f",&((vet+i)->altura));
   }
}

void ExibeArea(Retangulo *vet, int tam)
{
    for(int i=0;i<tam;i++)
    {
        float area = 0;
        area = (vet+i) -> largura * (vet+i)->altura;
        printf("A área do retângulo é: %.2f\n",area);
    }
}
int main()
{
    int tam;
    scanf("%d",&tam);
    Retangulo *vet =(Retangulo*)malloc(tam*sizeof(Retangulo));
    Preenche(vet,tam);
    ExibeArea(vet,tam);


    return 0;
}
