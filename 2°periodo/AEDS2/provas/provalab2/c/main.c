#include <stdio.h>
#include <stdlib.h>

void confereJogada(int matriz[4][4]){
    int DOWN = 0;
    int LEFT = 0;
    int RIGHT = 0;
    int UP = 0;
    for(int j = 0; j < 4; j++){
        for(int i = 0; i < 4; i++){
            if(matriz[i][j] != 0){
               if(matriz[i][j+1] == 0 && j < 3){
                RIGHT = 1;
               }
               else if(matriz[i][j] == matriz[i][j+1] && j < 3){
                RIGHT = 1;
               }
               else if(matriz[i][j] != 0 && j >= 1){
                 if(matriz[i][j-1] == 0 && j >= 1){
                LEFT = 1;
               }
                else if(matriz[i][j] == matriz[i][j-1]){
                LEFT = 1;
                }
               }
               else if(matriz[i+1][j] == 0 && i < 3){
                DOWN = 1;
               }
             else if(matriz[i][j] == matriz[i+1][j] && i < 3){
                DOWN = 1;
            }
            else if(matriz[i][j] == 0 && i >= 1){
                UP = 1;
            }
            else if(matriz[i][j] == matriz[i-1][j] && i >= 1){
                UP = 1;
            }

            }
        }
    }
   
     if(DOWN == 1){
        printf("DOWN ");
    }
    if(LEFT == 1){
        printf("LEFT ");
    }
    if(RIGHT == 1){
        printf("RIGHT ");
    }
    if(UP == 1){
        printf("UP\n");
    }
   else printf("NONE\n");

}

int main(){
    int i;
    scanf("%d",&i);
    int u = 0;
    while(u < i){
        int matriz[4][4];
        for(int j = 0; j < 4; j++){
            for(int z = 0; z < 4; z++){
                scanf("%d",&matriz[j][i]);
            }
        }
        confereJogada(matriz);
    }


    return 0;
}
