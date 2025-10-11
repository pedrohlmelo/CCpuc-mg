#include <stdio.h>
#include <stdlib.h>
#include <err.h>


typedef struct Celula {
	int elemento;        
	struct Celula* prox; 
} Celula;

Celula* novaCelula(int elemento) {
   Celula* nova = (Celula*) malloc(sizeof(Celula));
   nova->elemento = elemento;
   nova->prox = NULL;
   return nova;
}

Celula* topo; 

void start () {
   topo = NULL;
}

void inserir(int x) {
   Celula* tmp = novaCelula(x);
   tmp->prox = topo;
   topo = tmp;
   tmp = NULL;
}

int remover() {

   int resp = topo->elemento;
   Celula* tmp = topo;
   topo = topo->prox;
   tmp->prox = NULL;
   free(tmp);
   tmp = NULL;
   return resp;
}



void mostrar() {
   Celula* i;
   for(i = topo; i != NULL; i = i->prox) {
      printf("%d\n", i->elemento);
   }

}
int main(){

     inserir(5);
     mostrar();



    return 0;
}