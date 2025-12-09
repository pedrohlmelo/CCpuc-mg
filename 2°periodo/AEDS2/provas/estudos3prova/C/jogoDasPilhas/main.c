#include <stdlib.h>
#include <stdio.h>

int main(){

    int N;
    scanf("%d",&N);
    while(N != 0){
        int numeros[N*3];
        int soma = 0;
        for(int i=0; i < N*3; i++){
            scanf("%d",&numeros[i]);
            soma+=numeros[i];
        }
        if(soma % 3 == 0){
            printf("1\n");
        }
        else printf("0\n");
        scanf("%d",&N);

     }
   return 0;
}