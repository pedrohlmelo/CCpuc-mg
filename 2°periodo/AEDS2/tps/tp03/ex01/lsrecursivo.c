#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

// Verifica se só há vogais
bool Vogais(char letras[], int i) {
    if (letras[i] == '\0') return true;

    char c = tolower(letras[i]);
    if (c != 'a' && c != 'e' && c != 'i' && c != 'o' && c != 'u') {
        return false;
    }

    return Vogais(letras, i + 1);
}

// Verifica se só há consoantes
bool Consoantes(char letras[], int i) {
    if (letras[i] == '\0') return true;

    char c = tolower(letras[i]);
    if (!((c >= 'a' && c <= 'z') && c != 'a' && c != 'e' && c != 'i' && c != 'o' && c != 'u')) {
        return false;
    }

    return Consoantes(letras, i + 1);
}

// Verifica se é número inteiro 
bool ninteiro(char letras[], int i) {
    if (letras[i] == '\0') return true;

    if (!(letras[i] >= '0' && letras[i] <= '9')) {
        return false;
    }

    return ninteiro(letras, i + 1);
}

// Verifica se é número real 
bool nreal(char letras[], int i, int pontos) {
    if (letras[i] == '\0') return (pontos == 1);

    if (!(letras[i] >= '0' && letras[i] <= '9')) {
        if (letras[i] == '.' || letras[i] == ',') {
            pontos++;
        } else {
            return false;
        }
    }

    return nreal(letras, i + 1, pontos);
}

int main() {
    char caracteres[200];
    scanf(" %199[^\n]", caracteres);

    while (strcmp(caracteres, "FIM") != 0) {
        if (Vogais(caracteres, 0)) {
            printf("SIM ");
        } else {
            printf("NAO ");
        }

        if (Consoantes(caracteres, 0)) {
            printf("SIM ");
        } else {
            printf("NAO ");
        }

        if (ninteiro(caracteres, 0)) {
            printf("SIM ");
        } else {
            printf("NAO ");
        }

        if (nreal(caracteres, 0, 0)) {
            printf("SIM\n");
        } else {
            printf("NAO\n");
        }

        scanf(" %199[^\n]", caracteres);
    }

    return 0;
}

