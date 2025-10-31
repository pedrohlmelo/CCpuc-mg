#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h> 
#include <ctype.h>   
#include <strings.h> 

//registro game
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


//celula para pilha
typedef struct Celula {
    Game* game; 
    struct Celula* prox;
} Celula;

//pilha
typedef struct {
    Celula* primeiro; 
    Celula* ultimo;
    int tamanho;
} Pilha;

//procedimentos pilha
void formatar(Game* game, const char* linha);
void imprimir(const Game* game, int tam);
void free_game_memory(Game* game);
char** separarStringInterna(const char* texto, char separador, int* count);
char* trim(char* str);
Game* find_game_by_id(int id, Game* todosOsGames, int totalGamesCount);

//criacao pilha
Pilha* new_pilha() {
    Pilha* pilha = (Pilha*) malloc(sizeof(Pilha));
    pilha->primeiro = (Celula*) malloc(sizeof(Celula));
    pilha->primeiro->game = NULL;
    pilha->primeiro->prox = NULL;
    pilha->ultimo = pilha->primeiro;
    pilha->tamanho = 0;
    return pilha;
}

// (Push = Inserir Fim)
void pilha_push(Pilha* pilha, Game* game) {
    pilha->ultimo->prox = (Celula*) malloc(sizeof(Celula));
    pilha->ultimo->prox->game = game;
    pilha->ultimo->prox->prox = NULL;
    pilha->ultimo = pilha->ultimo->prox;
    pilha->tamanho++;
}

// (Pop = Remover Fim)
Game* pilha_pop(Pilha* pilha) {

    // Caminha até a PENÚLTIMA célula
    Celula* i;
    for (i = pilha->primeiro; i->prox != pilha->ultimo; i = i->prox);

    Game* removido = pilha->ultimo->game;
    free(pilha->ultimo);
    pilha->ultimo = i;
    pilha->ultimo->prox = NULL;
    pilha->tamanho--;
    return removido;
}

// (Mostrar)
void pilha_mostrar(Pilha* pilha) {
    int tam = 0;
    for (Celula* i = pilha->primeiro->prox; i != NULL; i = i->prox) {
        imprimir(i->game,tam); 
        tam++;
    }
}

//libera a pilha
void pilha_free(Pilha* pilha) {
    Celula* atual = pilha->primeiro;
    while (atual != NULL) {
        Celula* temp = atual;
        atual = atual->prox;
        free(temp); 
    }
    free(pilha); 
}



int main(void) {
    
    FILE* arquivo = fopen("/tmp/games.csv", "r");

    int games_capacity = 40000;
    int games_size = 0;
    Game* todosOsGames = (Game*) malloc(games_capacity * sizeof(Game));
    char linha[8192]; 

    fscanf(arquivo, "%[^\n]%*c", linha); 
    //loop para ler todos os games criando um vetor temporiario
    while (fscanf(arquivo, " %[^\n]%*c", linha) != EOF) {
        if (games_size >= games_capacity) {
            games_capacity *= 2;
            todosOsGames = (Game*) realloc(todosOsGames, games_capacity * sizeof(Game));
        }
        formatar(&todosOsGames[games_size], linha);
        games_size++;
    }
    fclose(arquivo);

    int ids_capacity = 100;
    int* ids = (int*) malloc(ids_capacity * sizeof(int));
    int countId = 0;
    char entrada[100];
    //loop para ler os ids criando um vetor temporario
    while (scanf("%s", entrada) == 1) {
        if (strcasecmp(entrada, "FIM") == 0) {
            break;
        }
        int valor = atoi(entrada);
        if (countId >= ids_capacity) {
            ids_capacity *= 2;
            ids = (int*) realloc(ids, ids_capacity * sizeof(int));
        }
        ids[countId++] = valor;
    }

    Pilha* pilha = new_pilha();
    
    for (int i = 0; i < countId; i++) {
        Game* gameEncontrado = find_game_by_id(ids[i], todosOsGames, games_size);
        if (gameEncontrado != NULL) {
            // Insere no fim 
            pilha_push(pilha, gameEncontrado);
        }
    }

    
    int qtd;
    scanf("%d", &qtd); 
    
    char ordem[10];
    int id;
     //for para comparar as ordens
    for (int i = 0; i < qtd; i++) {
        scanf("%s", ordem);
        Game* gameParaAcao = NULL;
        Game* gameRemovido = NULL;

        // --- LÓGICA DE COMANDOS DA PILHA ---
        
        // Comando 'I' (Push = Inserir Fim)
        if (strcmp(ordem, "I") == 0) {
            scanf("%d", &id);
            gameParaAcao = find_game_by_id(id, todosOsGames, games_size);
            if (gameParaAcao) {
                pilha_push(pilha, gameParaAcao);
            }
        } 
        // Comando 'R' (Pop = Remover Fim)
        else if (strcmp(ordem, "R") == 0) {
            gameRemovido = pilha_pop(pilha);
            if (gameRemovido) {
                printf("(R) %s\n", gameRemovido->name);
            }
        }
    }

    // Imprime a pilha final
    pilha_mostrar(pilha);

    
    free(ids);
    pilha_free(pilha);
    for (int i = 0; i < games_size; i++) {
        free_game_memory(&todosOsGames[i]);
    }
    free(todosOsGames);

    return 0;
}

//acha as informcoes do jogo por id
Game* find_game_by_id(int id, Game* todosOsGames, int totalGamesCount) {
    for (int i = 0; i < totalGamesCount; i++) {
        if (todosOsGames[i].id == id) {
            return &todosOsGames[i];
        }
    }
    return NULL; 
}
//imprime no formato certo
void imprimir(const Game* game, int n) {
    printf("[%d] => %d ## %s ## %s ## %d ## ",n, game->id, game->name, game->releaseDate, game->estimatedOwners);

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


void formatar(Game* game, const char* linha) {
    char** campos = NULL;
    int campos_count = 0;
    char* campoAtual = (char*) malloc(2048);
    int campoAtual_len = 0;
    bool dentroDeAspas = false;

    for (int i = 0; linha[i] != '\0'; i++) {
        char c = linha[i];
        if (c == '"') {
            dentroDeAspas = !dentroDeAspas;
        } else if (c == ',' && !dentroDeAspas) {
            campoAtual[campoAtual_len] = '\0';
            campos_count++;
            campos = (char**) realloc(campos, campos_count * sizeof(char*));
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
    campos = (char**) realloc(campos, campos_count * sizeof(char*));
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

    game->releaseDate = (char*) malloc(11);
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
    
    for (int i = 0; i < campos_count; i++) free(campos[i]);
    free(campos);
    for (int i = 0; i < dataPartes_count; i++) free(dataPartes[i]);
    free(dataPartes);
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

    int temp_count = 1;
    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == separador) temp_count++;
    }
    
    char** resultado = (char**) malloc(temp_count * sizeof(char*));
    char itemAtual[1024] = {0};
    int itemAtual_len = 0;
    int resultado_idx = 0;

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