#include <stdio.h>
#include <stdlib.h>

typedef struct Celula{
   int elemento;
   struct Celula *prox;
}Celula;

Celula *novaCelula(int elemento){
    Celula *nova = (Celula*)malloc(sizeof(Celula));
    nova -> elemento = elemento;
    nova -> prox = NULL;
    return nova;
}

Celula *primeiro;
Celula *ultimo;

void start(){
    primeiro = novaCelula(-1);
    ultimo = primeiro;
}

void inserir(int x){
    ultimo -> prox = novaCelula(x);
    ultimo = ultimo -> prox;
}
 
int remover(int valor){
    Celula *anterior = primeiro;
    Celula *atual = primeiro -> prox;
    while(atual != NULL && atual -> elemento != valor){
        anterior = atual;
        atual = atual -> prox;
    }
    anterior -> prox = atual -> prox;

    int resp = atual->elemento;
    free(atual);
    return resp;
}
void mostrar(){
    Celula *i;
    for(i = primeiro -> prox; i != NULL; i = i -> prox){
        printf("%d\n",i -> elemento);
    }
}
int main(){
    start();
     inserir(5);
     inserir(3);
     remover(5);
     mostrar();
    return 0;
}