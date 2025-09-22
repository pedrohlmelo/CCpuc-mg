#include <stdio.h>
#include <stdlib.h>

void verificaAltura(int alturas[], int N, int H){
	int contagem = 0;
	for(int i = 0; i < N; i++){
		if(alturas[i] <= H){// se a altura do brinquedo for menor ou igual a altura informada, o brinquedo podera ser usado
			contagem++;
		}
	}
	printf("%d\n",contagem);
}
int main(){


      int N,H;
      scanf("%d%d",&N,&H);
     
     if( 1 <= N <= 6 && 90 <= H <= 200){ //verifica as condicoes da questao 
      int alturas[N];

      for(int i = 0; i < N; i++){
	      scanf("%d",&alturas[i]); //guarda as N alturas dos brinquedos
      }
      int conta = 0;
      for(int i = 0; i < N; i++){ //para percorrer e verificar se as alturas dos brinquedos estao nos conformes da questao

      if(90 <= alturas[i] <=200){ //padrao da altura
	      conta ++;
          }
      }
      
     if(conta == N){ //significa que todas as alturas informadas estao no padrao entre 90 e 200 cm
     verificaAltura(alturas,N,H);//chama o verificador para ver a quantidade de brinquedos permitidos
      }
      
   
	return 0;
    }
}
