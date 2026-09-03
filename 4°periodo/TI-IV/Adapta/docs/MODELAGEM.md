# Adapta — Modelagem do Projeto

> Documento derivado de `docs/memoria.md` (fonte única de verdade do TI-IV).
> Aqui a memória é traduzida em modelo de domínio, fluxos, arquitetura e decisões
> técnicas fechadas para a Sprint 2. Tudo que a memória marca como `⬜ EM ABERTO`
> e que **não** precisava ser decidido agora continua em aberto (seção 8).

---

## 1. Proposta em uma frase

O Adapta é um app mobile (Flutter) de estudo por questões que **decide pelo aluno o que
estudar agora**. O aluno não navega por menus: ele abre o app, recebe uma fila de estudo
pronta e executa.

A fila é negociada por três sistemas que o aluno nunca vê separadamente:

| Pilar | Pergunta que responde | Injeta na fila | Requisitos |
|---|---|---|---|
| 1. Recomendação Adaptativa (IA) | "Qual a próxima melhor questão para o nível dele?" | conteúdo novo | RF03, RF06 |
| 2. Previsor de Esquecimento (IA) | "O que está prestes a ser esquecido?" | revisões | RF07, RF08 |
| 3. Grafo de Conhecimento | "O que é elegível, em que ordem, e onde está a lacuna?" | filtro + correção de lacuna | RF09 |

Os dois modelos de IA são treinados com **dataset sintético** (não há usuários reais).
O grafo é **curado à mão**, começando por uma única matéria.

---

## 2. Modelo de domínio

### 2.1 Entidades (espelham a seção 9 da memória)

```
Usuario ──1:N── Historico_Estudo ──N:1── Questao ──1:N── Alternativa
   │                                          │
   │                                          N:1
   │                                          ▼
   ├──N:M (Nivel_Memoria)──────────────── Assunto ──N:1── Materia
   │                                          │
   └──N:M (Proficiencia)──────────────────────┘
                                              │
                          Grafo_Dependencia (Assunto → Assunto, peso)
```

| Entidade | Papel no app | Classe Dart |
|---|---|---|
| `Usuario` | aluno ou admin; senha armazenada como hash | `Usuario` |
| `Materia` | filtro principal (RF02) | `Materia` |
| `Assunto` | tópico de estudo **e vértice do grafo** | `Assunto` |
| `Grafo_Dependencia` | aresta `prerequisito → dependente` com `peso` | `Dependencia` |
| `Questao` | enunciado + explicação + dificuldade declarada | `Questao` |
| `Alternativa` | opções com `letra` e flag `correta` | `Alternativa` |
| `Historico_Estudo` | evento `(aluno, questão, acertou, data, tempo)` — realimenta os modelos | `HistoricoEstudo` |
| `Nivel_Memoria` | retenção estimada por (aluno, assunto) — painel de esquecimento | `NivelMemoria` |
| `Proficiencia` | nível estimado por (aluno, assunto) — recomendação | `Proficiencia` |

### 2.2 Invariantes que o **app** garante (o banco não garante)

- O grafo de dependências é um **DAG**. O painel admin (RF11) rejeita aresta que feche ciclo.
- Toda `Questao` pertence a exatamente um `Assunto` (vértice do grafo).
- Cada `Questao` tem exatamente **uma** `Alternativa` com `correta = 1`.
- `Usuario.senha` nunca é texto puro.

### 2.3 O núcleo dos modelos de IA

- Pilar 1 consome `[id_usuario, id_questao, acertou]` de `Historico_Estudo`.
- Pilar 2 consome `[dias_desde_ultimo_estudo, complexidade, qtd_revisoes] → lembrou`.

Logo, `Historico_Estudo` e `Nivel_Memoria` são as tabelas que **precisam existir e ser
alimentadas desde a Sprint 2**, mesmo sem modelo algum rodando — são o dataset futuro.

---

## 3. Fluxos de usuário

### Aluno
1. Cadastro / login (RF01)
2. Escolhe matéria ou "estudo geral" (RF02)
3. Home: saúde da memória por assunto, alertas, lacuna detectada, botão "Estudar hoje"
4. Sessão: fila → questão → responde → feedback imediato + explicação (RF04, RF05) → grava histórico
5. Mapa de conhecimento (grafo colorido), trilha até objetivo, histórico (RF10)

### Admin (uso interno do grupo, RF11)
1. Login com `tipo = admin`
2. CRUD de matérias, assuntos, arestas do grafo (com validação de ciclo), questões + alternativas

---

## 4. O que a Sprint 2 entrega (escopo deste scaffold)

| Item da sprint | O que existe no código |
|---|---|
| Setup Flutter + banco local | projeto criado, `sqflite`, DDL das 9 tabelas, seed inicial |
| Cadastro e autenticação (RF01) | telas de login/cadastro, `UsuarioRepository`, hash SHA-256 + salt |
| Estrutura do Painel Admin (RF11) | rota `/admin` com menu e telas-esqueleto (matérias, assuntos, grafo, questões) |
| Fluxo de escolha de matérias (RF02) | tela lista matérias do banco + opção "Estudo geral" |
| Interface básica de questões (RF04) | tela mostra enunciado + alternativas, marca acerto/erro, grava `Historico_Estudo` |

Fora da Sprint 2 (só pastas/interfaces reservadas): fila de estudo (RF03), adaptação de
dificuldade (RF06), painel de esquecimento (RF07/08), diagnóstico de causa-raiz (RF09),
histórico (RF10), mapa do grafo, trilha.

---

## 5. Arquitetura do app Flutter

Feature-first com três camadas por feature. Os pilares ficam isolados em `lib/pilares/`
porque são o diferencial do projeto e serão desenvolvidos por pessoas diferentes.

```
lib/
├── main.dart                   ponto de entrada (ProviderScope)
├── app.dart                    MaterialApp.router + tema
├── core/                       infraestrutura compartilhada
│   ├── database/               abertura do SQLite, DDL, seed, provider
│   ├── seguranca/              hash de senha
│   ├── router/                 rotas (go_router)
│   └── tema/                   cores e tipografia
├── features/                   telas e regras por funcionalidade
│   ├── autenticacao/           RF01
│   ├── materias/               RF02
│   ├── questoes/               RF04 / RF05
│   ├── home/                   tela inicial (esqueleto)
│   └── admin/                  RF11
└── pilares/                    os três motores (interfaces + stubs)
    ├── grafo/                  Pilar 3 — DAG, travessias
    ├── recomendacao/           Pilar 1 — próxima questão
    └── esquecimento/           Pilar 2 — retenção estimada
```

Camadas dentro de cada feature:

- `domain/` — classes puras (sem Flutter, sem SQL). Testáveis sozinhas.
- `data/` — repositórios que falam com o `Database`. Testados com SQLite em memória.
- `presentation/` — widgets. Recebem dados via Riverpod.

Regra de dependência: `presentation → data → domain`. `pilares/` só dependem de `domain/`
e de `core/database` — nunca de widgets.

---

## 6. Decisões técnicas fechadas nesta sprint

| Decisão | Escolha | Motivo |
|---|---|---|
| Banco local | **sqflite** (SQLite) | RNF04 offline-first; DDL direta da seção 9; sem codegen; testável em memória com `sqflite_common_ffi` |
| Gerência de estado | **flutter_riverpod** | providers testáveis sem `BuildContext`; fácil injetar banco em memória nos testes |
| Navegação | **go_router** | rotas nomeadas, guarda de rota para admin |
| Hash de senha | **SHA-256 + salt por usuário** (`package:crypto`) | atende "nunca texto puro" sem dependência nativa. Trocar por bcrypt/argon2 se sair do escopo acadêmico |
| Alternativas por questão | **variável** (tabela própria, `letra` ordena) | memória já modela como 1:N; 5 fixas vira só validação no admin |
| Representação do grafo em memória | **lista de adjacência** dupla (`saida` e `entrada`) | RF09 caminha para trás, propagação caminha para frente; índices nas duas colunas no SQL |
| Onde o grafo roda | **no dispositivo** | dezenas de vértices no MVP; RNF02 (2 s) e RNF04 (offline) |
| Nomes no código | português sem acento, como a memória | casar com o modelo de dados |
| Linguagens | **app: 100 % Dart/Flutter; backend: Java + Spring** (projeto separado, ainda não criado) | restrição do grupo. A casca Android gerada usa `MainActivity.java`; os scripts Gradle `.kts` são ferramenta de build do Flutter, não código do app |

---

## 7. Estratégia de testes

- **Repositórios**: `sqflite_common_ffi` com `inMemoryDatabasePath`. Cada teste sobe o schema do zero.
- **Domínio / pilares**: testes unitários puros (ex.: detecção de ciclo no grafo).
- **Widgets**: `flutter_test` com `ProviderScope(overrides: [...])` injetando repositórios fake.

Rodar: `flutter test`.

---

## 8. Continua em aberto (não bloqueia a Sprint 2)

- Algoritmos dos Pilares 1 e 2, geração dos datasets sintéticos, métricas.
- Backend Java + Spring: definido como stack, mas ainda sem projeto. Hoje o app é 100 % local (SQLite).
  Quando o backend existir, os repositórios em `data/` viram a fronteira de sincronização.
- Matéria do MVP e curadoria do grafo (seed atual usa Matemática só como exemplo).
- `Nivel_Memoria` × `Proficiencia`: mantidas separadas (conceitos diferentes); fundir depois se atrapalhar.
- Tabela `Sessao_Estudo`: não criada. `Historico_Estudo` atende RF10.
- RF12 (mapa) e trilha: sem RF; pasta `pilares/grafo` já prevê as travessias.
- Biblioteca de visualização do grafo.
