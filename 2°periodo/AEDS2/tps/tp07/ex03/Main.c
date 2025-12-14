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


typedef struct No {
    Game* elemento;
    struct No* esq;
    struct No* dir;
    int altura; 
} No;


long comparacoes = 0;

int getAltura(No* no);
int getMax(int a, int b);
int getFatorBalanceamento(No* no);
No* rotacionarDireita(No* y);
No* rotacionarEsquerda(No* x);
No* novoNo(Game* game);
No* inserirAVL(No* no, Game* game);
bool pesquisarAVL(No* no, char* nome);
void freeAVL(No* no);


void formatar(Game* game, const char* linha);
char** separarStringInterna(const char* texto, char separador, int* count);
char* trim(char* str);
void free_game_memory(Game* game);
Game* find_game_by_id(int id, Game* todosOsGames, int totalGamesCount);

No* novoNo(Game* game) {
    No* no = (No*)malloc(sizeof(No));
    no->elemento = game;
    no->esq = NULL;
    no->dir = NULL;
    no->altura = 1; 
    return no;
}


int getAltura(No* no) {
    if (no == NULL) return 0;
    return no->altura;
}

int getMax(int a, int b) {
    return (a > b) ? a : b;
}

int getFatorBalanceamento(No* no) {
    if (no == NULL) return 0;
    return getAltura(no->esq) - getAltura(no->dir);
}

No* rotacionarDireita(No* y) {
    No* x = y->esq;
    No* T2 = x->dir;

    x->dir = y;
    y->esq = T2;

    y->altura = getMax(getAltura(y->esq), getAltura(y->dir)) + 1;
    x->altura = getMax(getAltura(x->esq), getAltura(x->dir)) + 1;

    return x; 
}

No* rotacionarEsquerda(No* x) {
    No* y = x->dir;
    No* T2 = y->esq;

    y->esq = x;
    x->dir = T2;

    x->altura = getMax(getAltura(x->esq), getAltura(x->dir)) + 1;
    y->altura = getMax(getAltura(y->esq), getAltura(y->dir)) + 1;

    return y; 
}

No* inserirAVL(No* no, Game* game) {
    if (no == NULL) return novoNo(game);

    int cmp = strcmp(game->name, no->elemento->name);

    if (cmp < 0)
        no->esq = inserirAVL(no->esq, game);
    else if (cmp > 0)
        no->dir = inserirAVL(no->dir, game);
    else
        return no; 

    no->altura = 1 + getMax(getAltura(no->esq), getAltura(no->dir));

    int balance = getFatorBalanceamento(no);


    if (balance > 1 && strcmp(game->name, no->esq->elemento->name) < 0)
        return rotacionarDireita(no);

    if (balance < -1 && strcmp(game->name, no->dir->elemento->name) > 0)
        return rotacionarEsquerda(no);

    if (balance > 1 && strcmp(game->name, no->esq->elemento->name) > 0) {
        no->esq = rotacionarEsquerda(no->esq);
        return rotacionarDireita(no);
    }

    if (balance < -1 && strcmp(game->name, no->dir->elemento->name) < 0) {
        no->dir = rotacionarDireita(no->dir);
        return rotacionarEsquerda(no);
    }

    return no; 
}

bool pesquisarAVL(No* no, char* nome) {
    if (no == NULL) {
        return false;
    }

    int cmp = strcmp(nome, no->elemento->name);

    if (cmp == 0) {
        comparacoes++;
        return true;
    } else if (cmp < 0) {
        comparacoes++;
        printf(" esq");
        return pesquisarAVL(no->esq, nome);
    } else {
        comparacoes++;
        printf(" dir");
        return pesquisarAVL(no->dir, nome);
    }
}

void freeAVL(No* no) {
    if (no != NULL) {
        freeAVL(no->esq);
        freeAVL(no->dir);
        free(no);
    }
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

    No* raiz = NULL;
    char entrada[1000];

    while (1) {
        if (scanf(" %[^\n]", entrada) == EOF) break;
        if (strcmp(entrada, "FIM") == 0) break;

        int id = atoi(entrada);
        Game* jogo = find_game_by_id(id, todosOsGames, games_size);
        if (jogo != NULL) {
            raiz = inserirAVL(raiz, jogo);
        }
    }

    while (1) {
        if (scanf(" %[^\n]", entrada) == EOF) break;
        if (strcmp(entrada, "FIM") == 0) break;

        printf("%s: raiz", entrada);
        bool encontrou = pesquisarAVL(raiz, entrada);
        if (encontrou) {
            printf(" SIM\n");
        } else {
            printf(" NAO\n");
        }
    }

    clock_t fim = clock();
    double tempo = ((double)(fim - inicio)) / CLOCKS_PER_SEC * 1000.0; 

    FILE* log = fopen("889841_avl.txt", "w"); 
    if (log) {
        fprintf(log, "889841\t%.4f\t%ld\n", tempo, comparacoes);
        fclose(log);
    }

    freeAVL(raiz);
    for (int i = 0; i < games_size; i++) {
        free_game_memory(&todosOsGames[i]);
    }
    free(todosOsGames);

    return 0;
}