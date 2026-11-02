# Sprint 3: armazenamento, IA e grafos

## Arquitetura

```
Telas ── Riverpod ── Repositórios ── SQLite (fonte de verdade)
                         │
    ServicoAprendizado ──┤           ServicoSincronizacao ── Firestore
    (modelos e grafo)    │           (cópia, quando há internet)
                  Shared Preferences (configurações)
```

As telas só leem e gravam pelo SQLite, e o app funciona offline. O Firebase cuida
da conta e guarda uma cópia do progresso. Se ele não subir, o app abre só com o
SQLite. A IA e o grafo rodam no aparelho, em Dart; não há backend próprio.

## SQLite (`adapta.db`, versão 1)

| Tabela | Conteúdo |
|---|---|
| `Usuario` | Linha local de cada pessoa. `uid_firebase` liga à conta; sem senha, que fica no Firebase Auth |
| `Materia`, `Assunto` | Conteúdo. Cada assunto é um vértice do grafo |
| `Grafo_Dependencia` | Arestas `pré-requisito → dependente` com peso; PK composta e índices nas duas pontas |
| `Questao`, `Alternativa` | Questões, com imagem opcional e `dificuldade_calibrada` |
| `Historico_Estudo` | Cada resposta, com id uuid e `tempo_gasto` |
| `Nivel_Memoria` | Retenção por usuário e assunto |
| `Proficiencia` | θ por usuário e assunto |

As três últimas têm `sincronizado` e `atualizado_em`: toda escrita de progresso
grava `sincronizado = 0`.

O seed roda uma vez: 14 assuntos de Matemática com 3 questões cada, os 2 de
História e 3 questões com imagem. Se o aparelho tiver um `adapta.db` de build
antigo, com outro schema, ele é renomeado para `adapta.db.antigo` e o banco é recriado.

## Firestore e regras

```
usuarios/{uid}                     { nome, email, tipo }
usuarios/{uid}/historico/{id}
usuarios/{uid}/memoria/{id_assunto}
usuarios/{uid}/proficiencia/{id_assunto}
```

Pelas regras (`firestore.rules`), cada usuário lê e grava apenas o próprio documento
e essas três subcoleções, conta nova nasce `aluno`, ninguém muda o próprio `tipo`
e nada mais é acessível.

Sincronização: ao abrir o app, ao trocar de usuário, ao fim de uma sessão e quando a
internet volta, os pendentes sobem em `WriteBatch` de até 400 escritas. Em memória
e proficiência vence o `atualizado_em` mais recente; o histórico só recebe linhas
novas. Login em aparelho novo baixa o progresso da conta.

## Sessão

O app não pede login: quem chega é visitante, com `signInAnonymously()` quando há
internet, ou só local até a rede voltar. O cadastro usa `linkWithCredential`, que
mantém o uid e o progresso. Sair volta para um visitante novo.

## Shared Preferences (`lib/dados/preferencias.dart`)

`tema_modo`, `id_materia_selecionada`, `seed_concluido`, `versao_conteudo`,
`ultima_sincronizacao`, `data_ultima_sessao`.

## Modelos de IA

Treinados em Python (`ia/`) sobre **dados simulados** de 500 alunos fictícios. As
métricas medem o quanto cada modelo recupera a simulação, não o desempenho com
alunos reais. Os números completos estão em `ia/relatorio.md`.

**Esquecimento:** regressão logística com `log1p(dias)`, `qtd_revisoes`,
`dificuldade` e `taxa_acerto_aluno`, em que a taxa é do aluno naquele assunto, com
suavização (acertos + 1) / (total + 2).

| Modelo (teste com alunos não vistos) | AUC | Acurácia | Brier |
|---|---:|---:|---:|
| Regressão logística | 0,787 | 0,754 | 0,164 |
| Fórmula fixa `exp(-dias / (1 + qtd_revisoes))` | 0,738 | 0,726 | 0,193 |

A retenção é recalculada do histórico ao abrir a home e após cada resposta, e só é
regravada se mudar ao menos 0,01, para não gerar pendências sem mudança real.

**Proficiência:** Rasch, P(acerto) = sigmoide(θ − b). O `b` de cada questão vem de
regressão logística com one-hot de aluno e questão, com correlação de 0,985 com o
`b` da simulação. Após cada resposta, θ += 0,4·(acertou − p) e b −= 0,05·(acertou − p).

**Fila (`MontadorFila`, RF03):** 10 questões, offline.

1. Elegíveis: assuntos sem pré-requisito vermelho.
2. Até 2 questões do assunto apontado pela causa raiz.
3. Cerca de 30% de revisões, do assunto mais urgente para o menos urgente.
4. O resto: o que nunca foi visto, com P(acerto) perto de 0,70 (0,80 depois de 2
   erros, 0,60 depois de 3 acertos), evitando repetir questões das últimas 24 h.

## Algoritmos de grafo (`lib/grafo/grafo_conhecimento.dart`)

| Algoritmo | Técnica | Uso |
|---|---|---|
| `temCiclo`, `criariaCiclo` | DFS | O admin recusa a aresta e mostra o caminho que a fecharia |
| `ordemTopologica`, `camadas` | Kahn; camada = maior distância até uma raiz | Fila e posição no mapa |
| `causaRaiz` | BFS reversa | Pré-requisito mais fraco abaixo de 0,5: (0,5 − força) × produto dos pesos do caminho |
| `propagarEsquecimento` | Percurso em ordem topológica | Teto do dependente: `peso·r_pre + (1 − peso)` |
| `gargalos` | Grau de saída | Borda mais grossa no mapa |

O Mapa de conhecimento (`/mapa`) desenha o grafo com `CustomPainter` dentro de
`InteractiveViewer`: verde ≥ 0,70, amarelo de 0,40 a 0,70, vermelho < 0,40, cinza
não estudado.
