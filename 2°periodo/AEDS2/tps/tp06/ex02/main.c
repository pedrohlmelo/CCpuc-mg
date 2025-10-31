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

//celula para lista
typedef struct Celula {
    Game* game; 
    struct Celula* prox;
} Celula;

//lista
typedef struct {
    Celula* primeiro; 
    Celula* ultimo;
    int tamanho;
} Lista;
//procedimentos lista
void formatar(Game* game, const char* linha);
void imprimir(const Game* game, int tam);
void free_game_memory(Game* game);
char** separarStringInterna(const char* texto, char separador, int* count);
char* trim(char* str);
Game* find_game_by_id(int id, Game* todosOsGames, int totalGamesCount);
//criacao lista
Lista* new_lista() {
    Lista* lista = (Lista*) malloc(sizeof(Lista));
    lista->primeiro = (Celula*) malloc(sizeof(Celula));
    lista->primeiro->game = NULL;
    lista->primeiro->prox = NULL;
    lista->ultimo = lista->primeiro;
    lista->tamanho = 0;
    return lista;
}

void lista_inserir_fim(Lista* lista, Game* game) {
    lista->ultimo->prox = (Celula*) malloc(sizeof(Celula));
    lista->ultimo->prox->game = game;
    lista->ultimo->prox->prox = NULL;
    lista->ultimo = lista->ultimo->prox;
    lista->tamanho++;
}


void lista_inserir_inicio(Lista* lista, Game* game) {
    Celula* nova = (Celula*) malloc(sizeof(Celula));
    nova->game = game;
    nova->prox = lista->primeiro->prox;
    lista->primeiro->prox = nova;
    if (lista->primeiro == lista->ultimo) {
        lista->ultimo = nova;
    }
    lista->tamanho++;
}

void lista_inserir_posicao(Lista* lista, Game* game, int pos) {
     if (pos == 0) {
        lista_inserir_inicio(lista, game);
    } else if (pos == lista->tamanho) {
        lista_inserir_fim(lista, game);
    } else {
        Celula* i = lista->primeiro;
        for (int j = 0; j < pos; j++) {
            i = i->prox;
        }
        Celula* nova = (Celula*) malloc(sizeof(Celula));
        nova->game = game;
        nova->prox = i->prox;
        i->prox = nova;
        lista->tamanho++;
    }
}

Game* lista_remover_inicio(Lista* lista) {
    if (lista->primeiro == lista->ultimo) {
        printf("Erro: Lista vazia!\n");
        return NULL;
    }

    Celula* tmp = lista->primeiro->prox;
    Game* removido = tmp->game;
    lista->primeiro->prox = tmp->prox;
    
    if (tmp == lista->ultimo) {
        lista->ultimo = lista->primeiro;
    }
    free(tmp);
    lista->tamanho--;
    return removido;
}

Game* lista_remover_final(Lista* lista) {
    if (lista->primeiro == lista->ultimo) {
        printf("Erro: Lista vazia!\n");
        return NULL;
    }

    Celula* i;
    for (i = lista->primeiro; i->prox != lista->ultimo; i = i->prox);

    Game* removido = lista->ultimo->game;
    free(lista->ultimo);
    lista->ultimo = i;
    lista->ultimo->prox = NULL;
    lista->tamanho--;
    return removido;
}

Game* lista_remover_posicao(Lista* lista, int pos) {
    if (lista->primeiro == lista->ultimo) {
        printf("Erro: Lista vazia!\n");
        return NULL;
    } else if (pos < 0 || pos >= lista->tamanho) {
        printf("Erro: Posição de remoção inválida!\n");
        return NULL;
    } else if (pos == 0) {
        return lista_remover_inicio(lista);
    } else if (pos == lista->tamanho - 1) {
        return lista_remover_final(lista);
    } else {
        Celula* i = lista->primeiro;
        for (int j = 0; j < pos; j++) {
            i = i->prox;
        }
        Celula* tmp = i->prox;
        i->prox = tmp->prox;
        Game* removido = tmp->game;
        free(tmp);
        lista->tamanho--;
        return removido;
    }
}

void lista_mostrar(Lista* lista) {
    int tam = 0;
    for (Celula* i = lista->primeiro->prox; i != NULL; i = i->prox) {
        imprimir(i->game,tam); 
        tam++;
    }
}
//libera a lista
void lista_free(Lista* lista) {
    Celula* atual = lista->primeiro;
    while (atual != NULL) {
        Celula* temp = atual;
        atual = atual->prox;
        free(temp); 
    }
    free(lista); 
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

    Lista* lista = new_lista();
    
    for (int i = 0; i < countId; i++) {
        Game* gameEncontrado = find_game_by_id(ids[i], todosOsGames, games_size);
        if (gameEncontrado != NULL) {
            lista_inserir_fim(lista, gameEncontrado);
        }
    }

    
    int qtd;
    scanf("%d", &qtd); 
    
    char ordem[10];
    int id, posicao;
     //for para comparar as ordens
    for (int i = 0; i < qtd; i++) {
        scanf("%s", ordem);
        Game* gameParaAcao = NULL;
        Game* gameRemovido = NULL;

        if (strcmp(ordem, "I*") == 0) {
            scanf("%d %d", &posicao, &id);
            gameParaAcao = find_game_by_id(id, todosOsGames, games_size);
            if (gameParaAcao) lista_inserir_posicao(lista, gameParaAcao, posicao);
        } 
        else if (strcmp(ordem, "II") == 0) {
            scanf("%d", &id);
            gameParaAcao = find_game_by_id(id, todosOsGames, games_size);
            if (gameParaAcao) lista_inserir_inicio(lista, gameParaAcao);
        }
        else if (strcmp(ordem, "IF") == 0) {
            scanf("%d", &id);
            gameParaAcao = find_game_by_id(id, todosOsGames, games_size);
            if (gameParaAcao) lista_inserir_fim(lista, gameParaAcao);
        }
        else if (strcmp(ordem, "RI") == 0) {
            gameRemovido = lista_remover_inicio(lista);
            if (gameRemovido) printf("(R) %s\n", gameRemovido->name);
        }
        else if (strcmp(ordem, "R*") == 0) {
            scanf("%d", &posicao);
            gameRemovido = lista_remover_posicao(lista, posicao);
            if (gameRemovido) printf("(R) %s\n", gameRemovido->name);
        }
        else if (strcmp(ordem, "RF") == 0) {
            gameRemovido = lista_remover_final(lista);
            if (gameRemovido) printf("(R) %s\n", gameRemovido->name);
        }
    }

    lista_mostrar(lista);

    
    free(ids);
    lista_free(lista);
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