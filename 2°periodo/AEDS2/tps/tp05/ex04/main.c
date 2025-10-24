#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <strings.h> 
#include <ctype.h>   
#include <time.h>    

typedef struct {
    
    int id;
    char* name;
    char* releaseDate;
    int estimatedOwners;
    float price;
    char** supportedLanguages;
    int supportedLanguages_count;
    int metacriticScore;
    float userScore;
    int achievements;
    char** publishers;
    int publishers_count;
    char** developers;
    int developers_count;
    char** categories;
    int categories_count;
    char** genres;
    int genres_count;
    char** tags;
    int tags_count;
} Game;


void formatar(Game* game, const char* linha);
void imprimir(const Game* game);
void free_game_memory(Game* game);
char** separarStringInterna(const char* texto, char separador, int* count);
char* trim(char* str);

// Funções do Quicksort
void quicksort(Game** games, int n, long* comparacoes, long* movimentacoes, double* tempo);
void quicksort_recursivo(Game** games, int esq, int dir, long* comparacoes, long* movimentacoes);
int particionar(Game** games, int esq, int dir, long* comparacoes, long* movimentacoes);
int compararGames(Game* a, Game* b, long* comparacoes); 
void swap(Game** games, int i, int j, long* movimentacoes);

void criarLog(double tempo, long comparacoes, long movimentacoes);


// Imprime um jogo formatado
void imprimir(const Game* game) {
    printf("=> %d ## %s ## %s ## %d ## ", game->id, game->name, game->releaseDate, game->estimatedOwners);

    if (game->price == 0.0f) {
        printf("%.1f", game->price); 
    } else {
        printf("%g", game->price); 
    }
    
    printf(" ## [");
    for (int i = 0; i < game->supportedLanguages_count; i++) {
        printf("%s", game->supportedLanguages[i]);
        if (i < game->supportedLanguages_count - 1) printf(", ");
    }
    printf("] ## %d ## %.1f ## %d ## [", game->metacriticScore, game->userScore, game->achievements);
    for (int i = 0; i < game->publishers_count; i++) {
        printf("%s", game->publishers[i]);
        if (i < game->publishers_count - 1) printf(", ");
    }
    printf("] ## [");
    for (int i = 0; i < game->developers_count; i++) {
        printf("%s", game->developers[i]);
        if (i < game->developers_count - 1) printf(", ");
    }
    printf("] ## [");
    for (int i = 0; i < game->categories_count; i++) {
        printf("%s", game->categories[i]);
        if (i < game->categories_count - 1) printf(", ");
    }
    printf("] ## [");
    for (int i = 0; i < game->genres_count; i++) {
        printf("%s", game->genres[i]);
        if (i < game->genres_count - 1) printf(", ");
    }
    printf("] ## [");
    for (int i = 0; i < game->tags_count; i++) {
        printf("%s", game->tags[i]);
        if (i < game->tags_count - 1) printf(", ");
    }
    printf("] ##\n");
}

// Lê uma linha do CSV e preenche a struct Game
void formatar(Game* game, const char* linha) {
    char** campos = NULL;
    int campos_count = 0;
    char* campoAtual = malloc(2048);
    int campoAtual_len = 0;
    bool dentroDeAspas = false;

    
    for (int i = 0; linha[i] != '\0'; i++) {
        char c = linha[i];
        if (c == '"') {
            dentroDeAspas = !dentroDeAspas;
        } else if (c == ',' && !dentroDeAspas) {
            campoAtual[campoAtual_len] = '\0';
            campos_count++;
            campos = realloc(campos, campos_count * sizeof(char*));
            campos[campos_count - 1] = strdup(campoAtual);
            campoAtual_len = 0;
        } else {
            if (campoAtual_len < 2047) {
                campoAtual[campoAtual_len++] = c;
            }
        }
    }
    campoAtual[campoAtual_len] = '\0';
    campos_count++;
    campos = realloc(campos, campos_count * sizeof(char*));
    campos[campos_count - 1] = strdup(campoAtual);
    free(campoAtual);

    for (int i = 0; i < campos_count; i++) {
        trim(campos[i]);
    }
    
   
    game->id = atoi(campos[0]);
    game->name = strdup(campos[1]);

    
    char dataSemVirgula[100] = {0};
    for (int i = 0, j = 0; campos[2][i] != '\0'; i++) {
        if (campos[2][i] != ',') {
            dataSemVirgula[j++] = campos[2][i];
        }
    }
    int dataPartes_count = 0;
    char** dataPartes = separarStringInterna(dataSemVirgula, ' ', &dataPartes_count);
    char *diaStr = "01", *mesStr = "Jan", *anoStr = "1970";

    if (dataPartes_count >= 3) {
        mesStr = dataPartes[0]; diaStr = dataPartes[1]; anoStr = dataPartes[2];
    } else if (dataPartes_count == 2) {
        mesStr = dataPartes[0]; anoStr = dataPartes[1]; diaStr = "01";
    }
    
    char diaFinal[3];
    if (strlen(diaStr) == 1) { 
        diaFinal[0] = '0';
        diaFinal[1] = diaStr[0];
        diaFinal[2] = '\0';
    } else { 
        strncpy(diaFinal, diaStr, 2); 
        diaFinal[2] = '\0'; 
    }

    char mesNum[3] = "00"; 
    if (strcmp(mesStr, "Jan") == 0) strcpy(mesNum, "01"); else if (strcmp(mesStr, "Feb") == 0) strcpy(mesNum, "02");
    else if (strcmp(mesStr, "Mar") == 0) strcpy(mesNum, "03"); else if (strcmp(mesStr, "Apr") == 0) strcpy(mesNum, "04");
    else if (strcmp(mesStr, "May") == 0) strcpy(mesNum, "05"); else if (strcmp(mesStr, "Jun") == 0) strcpy(mesNum, "06");
    else if (strcmp(mesStr, "Jul") == 0) strcpy(mesNum, "07"); else if (strcmp(mesStr, "Aug") == 0) strcpy(mesNum, "08");
    else if (strcmp(mesStr, "Sep") == 0) strcpy(mesNum, "09"); else if (strcmp(mesStr, "Oct") == 0) strcpy(mesNum, "10");
    else if (strcmp(mesStr, "Nov") == 0) strcpy(mesNum, "11"); else if (strcmp(mesStr, "Dec") == 0) strcpy(mesNum, "12");

    game->releaseDate = malloc(11); 
    sprintf(game->releaseDate, "%s/%s/%s", diaFinal, mesNum, anoStr);

    game->estimatedOwners = atoi(campos[3]);
    game->price = atof(campos[4]);
    
    
    char linguagensLimpas[1024] = {0};
    for (int i = 0, j = 0; campos[5][i] != '\0'; i++) {
        if (campos[5][i] != '[' && campos[5][i] != ']' && campos[5][i] != '\'') {
            linguagensLimpas[j++] = campos[5][i];
        }
    }
    game->supportedLanguages = separarStringInterna(linguagensLimpas, ',', &game->supportedLanguages_count);
    
    game->metacriticScore = atoi(campos[6]);
    game->userScore = atof(campos[7]);
    game->achievements = atoi(campos[8]);
    game->publishers = separarStringInterna(campos[9], ',', &game->publishers_count);
    game->developers = separarStringInterna(campos[10], ',', &game->developers_count);
    game->categories = separarStringInterna(campos[11], ',', &game->categories_count);
    game->genres = separarStringInterna(campos[12], ',', &game->genres_count);
    game->tags = separarStringInterna(campos[13], ',', &game->tags_count);
    
    // Libera memória dos campos temporários
    for (int i = 0; i < campos_count; i++) free(campos[i]);
    free(campos);
    for (int i = 0; i < dataPartes_count; i++) free(dataPartes[i]);
    free(dataPartes);
}



void quicksort(Game** games, int n, long* comparacoes, long* movimentacoes, double* tempo) {
    clock_t inicio = clock();
    quicksort_recursivo(games, 0, n - 1, comparacoes, movimentacoes);
    clock_t fim = clock();
    *tempo = ((double)(fim - inicio) * 1000) / CLOCKS_PER_SEC; // Retorna tempo em ms
}


void quicksort_recursivo(Game** games, int esq, int dir, long* comparacoes, long* movimentacoes) {
    if (esq < dir) {
        int pivo_idx = particionar(games, esq, dir, comparacoes, movimentacoes);
        quicksort_recursivo(games, esq, pivo_idx - 1, comparacoes, movimentacoes);
        quicksort_recursivo(games, pivo_idx + 1, dir, comparacoes, movimentacoes);
    }
}


int particionar(Game** games, int esq, int dir, long* comparacoes, long* movimentacoes) {
    Game* pivo = games[dir]; // Pivô é o último
    int i = (esq - 1); // Índice do menor elemento

    for (int j = esq; j < dir; j++) {
        
        if (compararGames(games[j], pivo, comparacoes) <= 0) {
            i++; 
            swap(games, i, j, movimentacoes);
        }
    }
    // Coloca o pivô na posição correta
    swap(games, i + 1, dir, movimentacoes);
    return (i + 1); 
}


int compararGames(Game* a, Game* b, long* comparacoes) {
    (*comparacoes)++;
    
    int cmpAno = strncmp(&a->releaseDate[6], &b->releaseDate[6], 4);
    if (cmpAno != 0) return cmpAno;

    (*comparacoes)++;
    
    int cmpMes = strncmp(&a->releaseDate[3], &b->releaseDate[3], 2);
    if (cmpMes != 0) return cmpMes;

    (*comparacoes)++;
    
    int cmpDia = strncmp(&a->releaseDate[0], &b->releaseDate[0], 2);
    if (cmpDia != 0) return cmpDia;

    (*comparacoes)++;
    
    if (a->id < b->id) return -1;
    if (a->id > b->id) return 1;
    
    return 0; 
}


void swap(Game** games, int i, int j, long* movimentacoes) {
    Game* temp = games[i];
    games[i] = games[j];
    games[j] = temp;
    (*movimentacoes) += 3; // 3 movimentações por troca
}




void criarLog(double tempo, long comparacoes, long movimentacoes) {
    FILE* log = fopen("889841_quicksort.txt", "w"); 
    
    fprintf(log, "889841\t%ld\t%ld\t%f.ms\n", comparacoes, movimentacoes, tempo);
    fclose(log);
}


int main(void) {
    
    FILE* arquivo = fopen("/tmp/games.csv", "r");

    int games_capacity = 40000;
    int games_size = 0;
    Game* gamesList = malloc(games_capacity * sizeof(Game));
    char linha[8192]; 

    fscanf(arquivo, "%[^\n]%*c", linha); 

    while (fscanf(arquivo, " %[^\n]%*c", linha) != EOF) {
        if (games_size >= games_capacity) { 
            games_capacity *= 2;
            gamesList = realloc(gamesList, games_capacity * sizeof(Game));
        }
        formatar(&gamesList[games_size], linha);
        games_size++;
    }
    fclose(arquivo);

    
    int vetor_capacity = 100; 
    int vetor_size = 0;
    Game** vetorJogos = malloc(vetor_capacity * sizeof(Game*)); 
    
    char entrada[100];
    while (scanf("%s", entrada) != EOF) {
        if (strcasecmp(entrada, "FIM") == 0) {
            break;
        }

        int idParaBuscar = atoi(entrada);
        bool achou = false;
        for (int i = 0; i < games_size; i++) {
            if (gamesList[i].id == idParaBuscar) {
                if (vetor_size >= vetor_capacity) { 
                    vetor_capacity *= 2;
                    vetorJogos = realloc(vetorJogos, vetor_capacity * sizeof(Game*));
                }
                vetorJogos[vetor_size] = &gamesList[i]; 
                vetor_size++;
                achou = true;
                break;
            }
        }
    }
    
    
    long comparacoes = 0;
    long movimentacoes = 0;
    double tempo = 0.0; 
    
    quicksort(vetorJogos, vetor_size, &comparacoes, &movimentacoes, &tempo);
    
    criarLog(tempo, comparacoes, movimentacoes);
    
    for (int i = 0; i < vetor_size; i++) {
        imprimir(vetorJogos[i]);
    }
    
    free(vetorJogos); 

    
    for (int i = 0; i < games_size; i++) {
        free_game_memory(&gamesList[i]);
    }
    free(gamesList); 

    return 0;
}



char* trim(char* str) {
    if (str == NULL) return NULL;
    char* end;
    while (isspace((unsigned char)*str)) str++;
    if (*str == 0) return str;
    end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    return str;
}


void free_game_memory(Game* game) {
    free(game->name);
    free(game->releaseDate);
    for (int i = 0; i < game->supportedLanguages_count; i++) free(game->supportedLanguages[i]);
    free(game->supportedLanguages);
    for (int i = 0; i < game->publishers_count; i++) free(game->publishers[i]);
    free(game->publishers);
    for (int i = 0; i < game->developers_count; i++) free(game->developers[i]);
    free(game->developers);
    for (int i = 0; i < game->categories_count; i++) free(game->categories[i]);
    free(game->categories);
    for (int i = 0; i < game->genres_count; i++) free(game->genres[i]);
    free(game->genres);
    for (int i = 0; i < game->tags_count; i++) free(game->tags[i]);
    free(game->tags);
}


char** separarStringInterna(const char* texto, char separador, int* count) {
    *count = 0;
    if (texto == NULL || texto[0] == '\0') {
        return NULL;
    }

    // Conta quantos separadores existem para alocar o array
    int temp_count = 1;
    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == separador) temp_count++;
    }
    
    char** resultado = malloc(temp_count * sizeof(char*));
    char itemAtual[1024] = {0};
    int itemAtual_len = 0;
    int resultado_idx = 0;

    // Preenche o array de strings
    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == separador) {
            itemAtual[itemAtual_len] = '\0';
            resultado[resultado_idx++] = strdup(trim(itemAtual));
            itemAtual_len = 0;
        } else {
            if (itemAtual_len < 1023) {
                itemAtual[itemAtual_len++] = texto[i];
            }
        }
    }
    itemAtual[itemAtual_len] = '\0'; 
    resultado[resultado_idx++] = strdup(trim(itemAtual));
    
    *count = resultado_idx;
    return resultado;
}