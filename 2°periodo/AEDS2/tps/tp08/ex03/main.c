#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
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

typedef struct Celula {
    Game* game;
    struct Celula* prox;
} Celula;

typedef struct {
    Celula* tabela[21];
    int comparacoes;
} Hash;

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

char** separarStringInterna(const char* texto, char separador, int* count) {
    *count = 0;
    if (texto == NULL || texto[0] == '\0') return NULL;
    int temp_count = 1;
    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == separador) temp_count++;
    }
    char** resultado = (char**)malloc(temp_count * sizeof(char*));
    char itemAtual[2048] = {0};
    int itemAtual_len = 0;
    int resultado_idx = 0;
    for (int i = 0; texto[i] != '\0'; i++) {
        if (texto[i] == separador) {
            itemAtual[itemAtual_len] = '\0';
            resultado[resultado_idx++] = strdup(trim(itemAtual));
            itemAtual_len = 0;
        } else {
            if (itemAtual_len < 2047) itemAtual[itemAtual_len++] = texto[i];
        }
    }
    itemAtual[itemAtual_len] = '\0';
    resultado[resultado_idx++] = strdup(trim(itemAtual));
    *count = resultado_idx;
    return resultado;
}

void formatar(Game* game, const char* linha) {
    char** campos = NULL;
    int campos_count = 0;
    char* campoAtual = (char*)malloc(4096);
    int campoAtual_len = 0;
    bool dentroDeAspas = false;

    for (int i = 0; linha[i] != '\0'; i++) {
        char c = linha[i];
        if (c == '"') {
            dentroDeAspas = !dentroDeAspas;
        } else if (c == ',' && !dentroDeAspas) {
            campoAtual[campoAtual_len] = '\0';
            campos_count++;
            campos = (char**)realloc(campos, campos_count * sizeof(char*));
            campos[campos_count - 1] = strdup(campoAtual);
            campoAtual_len = 0;
        } else {
            campoAtual[campoAtual_len++] = c;
        }
    }
    campoAtual[campoAtual_len] = '\0';
    campos_count++;
    campos = (char**)realloc(campos, campos_count * sizeof(char*));
    campos[campos_count - 1] = strdup(campoAtual);
    free(campoAtual);

    game->id = atoi(campos[0]);
    game->name = strdup(campos[1]);
    game->releaseDate = strdup(campos[2]);
    game->estimatedOwners = atoi(campos[3]);
    game->price = atof(campos[4]);
    
    for (int i = 0; i < campos_count; i++) free(campos[i]);
    free(campos);
}

void free_game_memory(Game* game) {
    if(game->name) free(game->name);
    if(game->releaseDate) free(game->releaseDate);
}

Game* find_game_by_id(int id, Game* todosOsGames, int totalGamesCount) {
    for (int i = 0; i < totalGamesCount; i++) {
        if (todosOsGames[i].id == id) {
            return &todosOsGames[i];
        }
    }
    return NULL;
}

int h(char* nome) {
    int resp = 0;
    for (int i = 0; nome[i] != '\0'; i++) {
        resp += (unsigned char)nome[i];
    }
    return resp % 21;
}

void hash_inicializar(Hash* hash) {
    for (int i = 0; i < 21; i++) {
        hash->tabela[i] = NULL;
    }
    hash->comparacoes = 0;
}

void hash_inserir(Hash* hash, Game* g) {
    if (g == NULL) return;
    
    int pos = h(g->name);
    
    Celula* nova = (Celula*)malloc(sizeof(Celula));
    nova->game = g;
    nova->prox = hash->tabela[pos];
    hash->tabela[pos] = nova;
}

void hash_pesquisar(Hash* hash, char* nome) {
    printf("%s: ", nome);
    int pos = h(nome);
    
    bool encontrou = false;
    Celula* atual = hash->tabela[pos];
    
    while (atual != NULL) {
        hash->comparacoes++;
        if (strcmp(atual->game->name, nome) == 0) {
            encontrou = true;
            break;
        }
        atual = atual->prox;
    }
    
    if (encontrou) {
        printf(" (Posicao: %d) SIM\n", pos);
    } else {
        printf(" (Posicao: %d) NAO\n", pos);
    }
}

void hash_free(Hash* hash) {
    for (int i = 0; i < 21; i++) {
        Celula* atual = hash->tabela[i];
        while (atual != NULL) {
            Celula* temp = atual;
            atual = atual->prox;
            free(temp);
        }
    }
}

int main(void) {
    clock_t inicio = clock();

    FILE* arquivo = fopen("/tmp/games.csv", "r");
    if (!arquivo) {
        printf("Erro ao abrir arquivo.\n");
        return 1;
    }

    int games_capacity = 5000;
    int games_size = 0;
    Game* todosOsGames = (Game*)malloc(games_capacity * sizeof(Game));
    char linha[4096];

    fgets(linha, sizeof(linha), arquivo); 
    while (fgets(linha, sizeof(linha), arquivo) != NULL) {
        linha[strcspn(linha, "\r\n")] = 0;
        if (strlen(linha) == 0) continue;

        if (games_size >= games_capacity) {
            games_capacity *= 2;
            todosOsGames = (Game*)realloc(todosOsGames, games_capacity * sizeof(Game));
        }
        formatar(&todosOsGames[games_size], linha);
        games_size++;
    }
    fclose(arquivo);

    Hash tabelaHash;
    hash_inicializar(&tabelaHash);
    char entrada[1000];

    while (1) {
        if (scanf(" %[^\n]", entrada) == EOF) break;
        if (strcmp(entrada, "FIM") == 0) break;

        int id = atoi(entrada);
        Game* jogo = find_game_by_id(id, todosOsGames, games_size);
        if (jogo != NULL) {
            hash_inserir(&tabelaHash, jogo);
        }
    }

    while (1) {
        if (scanf(" %[^\n]", entrada) == EOF) break;
        if (strcmp(entrada, "FIM") == 0) break;

        hash_pesquisar(&tabelaHash, entrada);
    }

    clock_t fim = clock();
    double tempo = ((double)(fim - inicio)) / CLOCKS_PER_SEC * 1000.0;

    FILE* log = fopen("889841_hashIndireta.txt", "w");
    if (log) {
        fprintf(log, "889841\t%.4f\t%d\n", tempo, tabelaHash.comparacoes);
        fclose(log);
    }

    hash_free(&tabelaHash);
    for (int i = 0; i < games_size; i++) {
        free_game_memory(&todosOsGames[i]);
    }
    free(todosOsGames);

    return 0;
}