#include <stdio.h>
#include <stdlib.h>
# include <stdbool.h>

typedef struct{
    char nome[20];
}Pokemon;

bool confereIguais(Pokemon pokemon1,Pokemon pokemon2){
    int tam1 = 0;
    int tam2 = 0;
    int count = 0;

    while(pokemon1.nome[tam1] != '\0'){//pega o tamanho do nome do 1
        tam1++;
    }
     while(pokemon2.nome[tam2] != '\0'){//pega o tamanho do nome do 2
        tam2++;
    }

    if(tam1 != tam2){// se os tamanhos foram diferentes, sabemos que nao sao o mesmo pomekon
        return false;
    }
    else{//se forem de tamanhos iguais
        for(int i = 0; i < tam1; i++){
            if(pokemon1.nome[i] ==  pokemon2.nome[i]){//vamos conferir quantos caracteres sao iguais
                count ++;
            }
        }
        if(count == tam1){//se todos os caracteres forem iguais
            return true;
        }
        else{//se so agluns caracteres forem iguais
            return false;
        }
    }

}

int main(){

  int N;
  scanf("%d",&N);
  Pokemon pokemons[N];
  int Nc[N];

  for(int i = 0; i < N ; i++){
    scanf(" %[^\n]",pokemons[i].nome);
  }

  for(int i = 0; i < N ; i++){
    Nc[i] = 0;//inicio cada pokemon com o valor"0"
  }

  for(int i = N-1; i >=0; i--){
    for(int j = 0; j < i; j++){
        if(confereIguais(pokemons[i],pokemons[j])){// se os pokemons ja existirem, troco o valor por 1
            Nc[j] = 1;
        }
    }
  }
  int soma = 0;
  for(int i = 0; i < N; i++){
    soma+=Nc[i];//pega todos os 1, que sao os que estao repetidos
  }
  int total = 151 - (N - soma);//total - (quantidade da entrada - repetidos)

  printf("Falta(m) %d pomekon(s).",total);

    return 0;
}