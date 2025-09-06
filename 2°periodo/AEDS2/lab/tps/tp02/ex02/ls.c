#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

bool Vogais(char letras[]) {
    for (int i = 0; letras[i] != '\0'; i++) {
        char c = tolower(letras[i]);
        if (c != 'a' && c != 'e' && c != 'i' && c != 'o' && c != 'u') {
            return false;
        }
    }
    return true;
}

bool Consoantes(char letras[]) {
    for (int i = 0; letras[i] != '\0'; i++) {
        char c = tolower(letras[i]);
        if (!((c >= 'a' && c <= 'z') && c != 'a' && c != 'e' && c != 'i' && c != 'o' && c != 'u')) {
            return false;
        }
    }
    return true;
}

bool ninteiro(char letras[]) {
    for (int i = 0; letras[i] != '\0'; i++) {
        if (!isdigit(letras[i])) {
            return false;
        }
    }
    return true;
}

bool nreal(char letras[]) {
    int pontos = 0;
    for (int i = 0; letras[i] != '\0'; i++) {
        if (!isdigit(letras[i])) {
            if (letras[i] == '.' || letras[i] == ',') {
                pontos++;
            } else {
                return false;
            }
        }
    }
    return (pontos == 1); 
}

int main(){

    char caracteres[200];
    scanf(" %199[^\n]", caracteres);

    while(strcmp(caracteres,"FIM") != 0){
        if(Vogais(caracteres)){
            printf("SIM ");
        }
        else printf("NAO ");
        if(Consoantes(caracteres)){
            printf("SIM ");
        }
        else printf("NAO ");
        if(ninteiro(caracteres)){
            printf("SIM ");
        }
        else printf("NAO ");
        if(nreal(caracteres)){
            printf("SIM\n");
        }
        else printf("NAO\n");

        scanf(" %199[^\n]", caracteres);
    }



    return 0;
}

