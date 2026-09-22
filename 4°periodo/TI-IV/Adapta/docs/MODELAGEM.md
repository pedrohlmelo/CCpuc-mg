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
1. Abre o app direto na tela inicial, sem login (RF14)
2. Vê saúde da memória por assunto, alertas e o botão "Estudar agora"
3. Se quiser, filtra por matéria ou fica no "estudo guiado" (RF02)
4. Sessão: fila → questão → responde → feedback imediato + explicação (RF04, RF05) → grava histórico
5. Histórico: questões respondidas por dia, resolução de cada uma e refazer (RF10, RF12, RF13)
6. Perfil: entrar, criar conta, tema e painel administrativo (RF01)
7. Adiante: mapa de conhecimento (grafo colorido) e trilha até um objetivo

### Admin (uso interno do grupo, RF11)
1. Entra pelo perfil, em "Painel administrativo"
2. Matérias, assuntos, arestas do grafo e questões + alternativas

---

## 4. O que esta etapa entrega

Depois da revisão do professor, o escopo do app Flutter foi redefinido: **telas e
navegação, sem funcionalidade implementada**. O que existia de consulta a banco,
autenticação e algoritmo saiu do app e passa a ser trabalho do backend.

| Item | Situação |
|---|---|
| Telas do aluno (inicial, matérias, sessão, histórico, resolução, perfil) | prontas |
| Telas de conta (login, cadastro) | prontas, fora da abertura do app |
| Painel administrativo (menu, matérias, assuntos, grafo, questões) | prontas |
| Navegação com abas e botão de voltar em toda tela interna | pronta |
| Banco local, repositórios, hash de senha, pilares | removidos do app |
| Dados de exemplo em memória para as telas | prontos |

Fora desta etapa: qualquer persistência, a fila real de estudo (RF03), a adaptação de
dificuldade (RF06), o painel de esquecimento calculado (RF07/08), o diagnóstico de
causa-raiz (RF09), o mapa do grafo e a trilha.

---

## 5. Arquitetura do app Flutter

Pastas por tipo de arquivo. A regra é que encontrar uma tela não dependa de saber a que
funcionalidade ela pertence.

```
lib/
├── main.dart                   ponto de entrada (ProviderScope)
├── app.dart                    MaterialApp.router + tema
├── telas/                      todas as telas: aluno/, auth/, admin/
├── navegacao/                  rotas (go_router) e a casca com a barra inferior
├── dados/                      modelos de apresentação, dados de exemplo e estado de UI
├── tema/                       cores, tipografia e claro/escuro
└── widgets/                    peças reutilizadas pelas telas
```

Regra de dependência: `telas → widgets → dados/tema`. Nenhum widget conhece SQL, HTTP ou
regra de negócio.

O mapa tela a tela está em `docs/TELAS.md`; o detalhe das pastas, em `docs/ESTRUTURA.md`.

---

## 6. Decisões técnicas desta etapa

| Decisão | Escolha | Motivo |
|---|---|---|
| Dados | **listas fixas em memória** (`lib/dados/dados_exemplo.dart`) | o app é protótipo de telas; persistência é do backend |
| Estado de interface | **flutter_riverpod** | providers testáveis, sem `BuildContext` |
| Navegação | **go_router** com `StatefulShellRoute` | abas com pilha própria e rotas nomeadas |
| Abertura do app | **tela inicial do aluno**, sem login | instrução do professor (RF14) |
| Login e painel admin | alcançados pelo **perfil** | tirar a autenticação do caminho de entrada |
| Voltar | `BotaoVoltar` em toda tela empilhada | com queda para a tela inicial quando não há pilha |
| Dependências | só `flutter_riverpod`, `go_router` e `shared_preferences` | saíram `sqflite`, `crypto`, `path`, `path_provider` |
| Nomes no código | português sem acento | casar com o modelo de dados |
| Linguagens | app 100 % Dart/Flutter; backend Java + Spring (a criar) | restrição do grupo |

---

## 7. Estratégia de testes

- **Navegação** (`test/widget/navegacao_test.dart`): cada tela abre, cada volta funciona,
  responder uma questão aparece no histórico. Usa as chaves `Key('tela_<nome>')`.
- **Dados de exemplo** (`test/dados/dados_exemplo_test.dart`): ids únicos, uma alternativa
  correta por questão, referências válidas entre questão, assunto e matéria.
- **Tema** (`test/widget/tema_toggle_test.dart`): alternância claro/escuro.
- **Capturas** (`test/capturas/`): gera PNGs das telas para os slides.

Rodar: `flutter test`.

---

## 8. Continua em aberto

- Backend Java + Spring: definido como stack, ainda sem projeto. É ele que passa a
  responder pelas 9 tabelas da seção 2, pela autenticação e pelos três pilares.
- Algoritmos dos Pilares 1 e 2, datasets sintéticos e métricas.
- Onde os algoritmos de grafo rodam depois que o backend existir.
- Matéria do MVP e curadoria do grafo (os dados de exemplo usam Matemática e História).
- Telas do mapa de conhecimento e da trilha até um objetivo.
- Como o app fará a integração: cliente HTTP, tratamento de erro e modo offline (RNF04).
