# Sprint 3: armazenamento, IA e grafos

## Arquitetura

```
Telas ── Riverpod ── Repositórios ── SQLite (fonte de verdade)
                         │
    ServicoAprendizado ──┤           ServicoSincronizacao ── Firestore
    (modelos e grafo)    │           (baixa o conteúdo, sobe o progresso)
                  Shared Preferences (configurações)
```

As telas só leem e gravam pelo SQLite, e o app funciona offline. O Firebase cuida
da conta, guarda o banco de questões e uma cópia do progresso. Se ele não subir, o app abre só com o
SQLite. A IA e o grafo rodam no aparelho, em Dart; não há backend próprio.

## Conteúdo

As questões vêm de provas reais do ENEM (INEP), obtidas pela API pública
[enem.dev](https://enem.dev). Por enquanto, 2022 e 2023. A API traz só a área, então
matéria, assunto e explicação foram classificados depois. Explicação gerada mostra um
aviso na tela enquanto `revisado` for falso.

O Firestore é a única fonte. Caminho: API → `ferramentas/conteudo/` → Firestore →
pacote inicial → SQLite. O app nunca chama a API.

- **Um documento por questão:** dá para baixar só o que mudou, e a conta de leituras
  acompanha o que cada aparelho realmente precisa.
- **Pacote inicial:** `lib/dados/banco/pacote_inicial.g.dart`, gerado do Firestore, traz
  toda a estrutura e ~100 questões sem imagem de internet. Assim, o primeiro acesso
  funciona em modo avião.
- **Download:** ao abrir online e quando a rede volta, o app lê `meta/conteudo`. Com versão
  nova, baixa `materias/*` e as questões por `atualizado_em`, em páginas de 300. Cada página
  fica gravada, então uma queda continua de onde parou. `atualizado_em` é único por
  documento, para o `startAfter` não pular ninguém.
- **Imagens por URL:** ficam no enem.dev, sem Storage, com `cached_network_image`. Sem
  cache e sem rede, a tela mostra a descrição, e a fila evita essas questões.
- **`ativo: false`:** tira a questão do app sem apagar, e o histórico continua válido.

## SQLite (`adapta.db`, versão 4)

| Tabela | Conteúdo |
|---|---|
| `Usuario` | Linha local de cada pessoa. `uid_firebase` liga à conta; sem senha, que fica no Firebase Auth |
| `Materia`, `Assunto` | Conteúdo, com `area` e `ativo` nos dois; a matéria tem também `sincronizado` e `atualizado_em` para o painel admin. Cada assunto é um vértice do grafo |
| `Grafo_Dependencia` | Arestas `pré-requisito → dependente` com peso; PK composta e índices nas duas pontas |
| `Questao`, `Alternativa` | Questões, com imagem opcional, `dificuldade_calibrada`, `fonte`, `explicacao_gerada`, `revisado`, `ativo`, `sincronizado` e `atualizado_em` |
| `Historico_Estudo` | Cada resposta, com id uuid e `tempo_gasto` |
| `Nivel_Memoria` | Retenção por usuário e assunto |
| `Proficiencia` | θ por usuário e assunto |

As três últimas têm `sincronizado` e `atualizado_em`: toda escrita de progresso
grava `sincronizado = 0`.

Migrações: a 2 acrescenta `area`, `fonte`, `explicacao_gerada` e `revisado`; a 3
acrescenta `ativo` na questão; a 4 acrescenta `ativo` em matéria e assunto e
`sincronizado`/`atualizado_em` em matéria e questão, para o painel admin. Continuam 9 tabelas. `imagem_local` fica sem uso. O pacote inicial é aplicado na criação do
banco e quando vier em versão maior que a salva. Se o aparelho tiver um `adapta.db` de build
antigo, com outro schema, ele é renomeado para `adapta.db.antigo` e o banco é recriado.

## Firestore e regras

```
meta/conteudo                      { versao, atualizado_em, total_questoes, dependencias_entre_materias }
materias/{id}                      { id, nome, area, assuntos, dependencias }
questoes/{id}                      { id, materia, assunto, dificuldade, dificuldade_irt, enunciado,
                                     explicacao, imagem, imagem_descricao, fonte, explicacao_gerada,
                                     revisado, ativo, confianca_classificacao, atualizado_em, alternativas }
usuarios/{uid}                     { nome, email, tipo }
usuarios/{uid}/historico/{id}
usuarios/{uid}/memoria/{id_assunto}
usuarios/{uid}/proficiencia/{id_assunto}
```

Pelas regras (`firestore.rules`), cada usuário lê e grava apenas o próprio documento
e essas três subcoleções, conta nova nasce `aluno`, ninguém muda o próprio `tipo`
e nada mais é acessível. `meta`, `materias` e `questoes` podem ser lidos por quem tem
sessão, inclusive o visitante anônimo, e só o admin escreve. Os scripts usam a conta de
serviço, que não passa pelas regras.

## Painel administrativo (RF11), offline primeiro

O admin grava no SQLite na hora, numa transação, sem esperar a rede
(`lib/dados/repositorios/admin_conteudo_repositorio.dart`), e as telas releem o banco logo em
seguida. O que ele mudou fica com `sincronizado = 0`: a questão, ou a matéria, já que assuntos
e arestas moram no documento dela (uma aresta entre matérias marca as duas). Na lista, um ícone
de nuvem riscada mostra o que ainda não subiu, e o painel inicial conta as alterações pendentes.

- **Exclusão lógica.** Matéria, assunto e questão nunca são apagados, porque histórico, memória e
  proficiência apontam para os ids. Excluir é `ativo = 0`, em cascata (matéria → assuntos →
  questões), e tira as arestas que tocam os assuntos desativados. "Mostrar inativos" permite
  reativar. O app do aluno ignora o que está inativo, e o histórico continua abrindo a questão.
- **Ids.** Matéria: maior id + 1. Assunto: `id_materia * 100 + n`, com o menor `n` livre.
  Questão do painel: de 9000001 a 9999999.
- **Validação.** A mesma do pacote: assunto e matéria ativos, enunciado e explicação, dificuldade
  1–3, 5 alternativas A–E com texto ou imagem e exatamente uma correta. Aresta que fecharia ciclo
  no grafo inteiro é recusada com o caminho, e o peso vai de 0,1 a 1,0.
- **Envio.** Logo depois de cada gravação, ao abrir o app e quando a rede volta, antes do
  download: as matérias pendentes viram `materias/{id}` completos, as arestas entre matérias são
  recalculadas para `meta/conteudo`, e cada questão pendente vira `questoes/{id}` com
  `atualizado_em` novo e único. Tudo vai numa transação com `versao + 1` e `total_questoes`. Deu
  certo: as linhas voltam a `sincronizado = 1` (só se não mudaram durante o envio) e, se o aparelho
  estava em dia, a versão nova fica salva, para ele não baixar de novo. Falhou: nada muda, e a
  próxima tentativa manda tudo outra vez.
- **Download.** `aplicarConteudo` não sobrescreve matéria, assunto, aresta ou questão pendente:
  a mudança local vence até subir.
- `ferramentas/conteudo/estrutura.py` só cria matérias que não existem, para não desfazer o painel;
  `--forcar` sobrescreve.

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
`ultima_sincronizacao`, `data_ultima_sessao`, `lingua_estrangeira`, `versao_banco`,
`ultima_sincronizacao_conteudo`. `versao_banco` é separada de `versao_conteudo`: o pacote
inicial sai com a mesma versão do Firestore, e o aparelho ainda precisa baixar o banco.

## Modelos de IA

Treinados em Python (`ia/`) sobre **dados simulados** de 500 alunos fictícios. As
métricas medem o quanto cada modelo recupera a simulação, não o desempenho com
alunos reais. Os números completos estão em `ia/relatorio.md`.

**Esquecimento:** regressão logística com `log1p(dias)`, `qtd_revisoes`,
`dificuldade` e `taxa_acerto_aluno`, em que a taxa é do aluno naquele assunto, com
suavização (acertos + 1) / (total + 2).

| Modelo (teste com alunos não vistos) | AUC | Acurácia | Brier |
|---|---:|---:|---:|
| Regressão logística | 0,799 | 0,761 | 0,158 |
| Fórmula fixa `exp(-dias / (1 + qtd_revisoes))` | 0,749 | 0,727 | 0,188 |

A retenção é recalculada do histórico ao abrir a home e após cada resposta, e só é
regravada se mudar ao menos 0,01, para não gerar pendências sem mudança real.

**Proficiência:** Rasch, P(acerto) = sigmoide(θ − b). O `b` de cada questão vem de
regressão logística com one-hot de aluno e questão, com correlação de 0,817 com o
`b` da simulação, sobre 410 questões. Ele fica em `questoes/{id}.dificuldade_irt` e chega
ao aparelho com a questão, sem sobrescrever uma calibração local. Questão sem `b` usa
`dificuldade - 2`. Após cada resposta, θ += 0,4·(acertou − p) e b −= 0,05·(acertou − p).

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

O Mapa de conhecimento (`/mapa`), visível só para administradores, desenha o grafo com `CustomPainter` dentro de
`InteractiveViewer`: verde ≥ 0,70, amarelo de 0,40 a 0,70, vermelho < 0,40, cinza
não estudado.
