# memoria.md — Contexto do Projeto

> Arquivo de memória do projeto. Serve como fonte única de verdade sobre **o que** estamos construindo e **por quê**.
> Decisões técnicas ainda em aberto estão marcadas com `⬜ EM ABERTO`.
> Sempre que uma decisão for fechada, atualizar aqui antes de codar.

---

## 1. Identificação

| Campo | Valor |
|---|---|
| Nome do app | Adapta |
| Disciplina | Trabalho Interdisciplinar IV (TI-4) |
| Tipo de entrega | Aplicação móvel |
| Framework | Flutter |
| Componente de IA | Sim — dois modelos preditivos |
| Estrutura de dados destacada | Grafo (não obrigatório, mas pontua na avaliação) |
| Público-alvo | Estudantes (ensino médio / pré-vestibular) |

---

## 2. Visão Geral

O app é uma plataforma de estudos por questões e revisões que **decide pelo aluno o que ele deve estudar agora**.

A premissa: o maior problema de quem estuda sozinho não é falta de conteúdo, é falta de direção. O aluno não sabe qual questão fazer, não sabe quando revisar o que já viu e, principalmente, não sabe *por que* está travando em um assunto — normalmente porque a base anterior está falha.

O app resolve isso com três camadas que trabalham juntas:

1. **O que estudar agora** → Sistema de Recomendação Adaptativa
2. **O que revisar antes de esquecer** → Previsor da Curva de Esquecimento
3. **Como os assuntos se relacionam** → Grafo de Conhecimento

O aluno abre o app e recebe uma fila de estudo pronta. Ele não escolhe — ele executa.

### Frase de posicionamento
> "Um app que sabe o que você precisa estudar hoje melhor do que você."

---

## 3. Pilar 1 — Sistema de Recomendação Adaptativa

### Conceito
Em vez de o aluno navegar por menus e escolher "quero questões de História", o sistema analisa o histórico de acertos e erros dele e seleciona **a próxima melhor questão** para o nível atual.

O objetivo é manter o aluno na zona de dificuldade ideal:
- Questão fácil demais → tédio, sensação de perda de tempo
- Questão difícil demais → frustração, abandono
- Questão calibrada → engajamento e progresso real

### O que o sistema precisa saber
O núcleo do modelo é uma relação simples entre três coisas:

```
[ID_do_Aluno, ID_da_Questao, Acertou_ou_Errou]
```

A partir desse histórico, o sistema infere o nível de proficiência do aluno por assunto e a dificuldade real de cada questão (não a dificuldade que o autor declarou, mas a que os alunos demonstraram na prática).

### Comportamento esperado no app
- O aluno nunca vê uma lista vazia — sempre há uma próxima questão sugerida
- A recomendação muda conforme o desempenho recente (errou muito → o sistema alivia; acertou em sequência → o sistema pressiona)
- O aluno pode filtrar por matéria se quiser, mas o padrão é o modo "estudo guiado"

### Dados de treino
Como o app é novo, não existe base histórica de usuários reais. O modelo inicial será treinado com **dataset sintético** — alunos fictícios respondendo questões, gerado programaticamente para simular perfis de proficiência variados.

> `⬜ EM ABERTO` — algoritmo, biblioteca e estratégia de treino ainda não definidos.

---

## 4. Pilar 2 — Previsor da Curva de Esquecimento

### Conceito
Apps de repetição espaçada (como o Anki) usam fórmulas matemáticas **fixas e iguais para todo mundo** para agendar revisões. Aqui a proposta é diferente: um modelo que aprende o **ritmo individual de esquecimento** de cada aluno e prevê quando ele vai esquecer um assunto específico.

O problema é tratado como classificação binária: dado o estado atual de um item de estudo, **o aluno vai lembrar ou vai esquecer?**

### Variáveis consideradas
```
dias_desde_o_ultimo_estudo
complexidade_da_questao
qtd_revisoes_anteriores
→ lembrou (0 ou 1)
```

O modelo aprende o peso de cada variável — por exemplo, quanto o número de revisões anteriores realmente compensa o tempo passado desde o último contato com o conteúdo.

### Comportamento esperado no app
Isso vira o elemento visual mais forte da tela inicial: a **barra de saúde da memória**.

Cada assunto que o aluno estudou tem um indicador de retenção estimada, que decai com o tempo:

- 🟩 **Consolidado** — retenção alta, sem urgência
- 🟨 **Em risco** — começando a decair, revisão recomendada
- 🟥 **Crítico** — prestes a ser esquecido, revisar hoje

Mensagens diretas ao aluno, do tipo:
> "Você tem 85% de chance de esquecer *Idade Média* amanhã. Revise hoje."

### Dados de treino
Também dataset sintético, simulando sessões de revisão ao longo do tempo com diferentes perfis de retenção.

> `⬜ EM ABERTO` — algoritmo, features finais e forma de calibração ainda não definidos.

---

## 5. Pilar 3 — Grafo de Conhecimento

> O uso de grafos **não é obrigatório** no TI-4, mas é valorizado na avaliação. A decisão do grupo é incorporá-lo como **estrutura central do domínio**, não como enfeite: sem o grafo, os dois modelos anteriores continuam funcionando, mas ficam cegos para a relação entre os assuntos.

### Conceito
Conhecimento não é uma lista, é uma rede. Ninguém aprende "Equação do 2º grau" sem antes dominar "Equação do 1º grau"; ninguém entende "Revolução Industrial" sem "Iluminismo".

O app modela todo o conteúdo como um **grafo direcionado de pré-requisitos**:

- **Vértices** → assuntos (ex.: *Funções*, *Logaritmo*, *Idade Média*)
- **Arestas** → relação de dependência `A → B` ("A é pré-requisito de B")
- **Peso da aresta** → força da dependência (o quanto A é realmente necessário para B)

```
        Equação 1º grau
               │
        ┌──────┴──────┐
        ▼             ▼
  Equação 2º grau   Funções
        │             │
        └──────┬──────┘
               ▼
           Logaritmo
```

### Para que o grafo é usado

**a) Diagnóstico de causa-raiz (o uso mais forte)**
Quando o aluno erra repetidamente um assunto, o sistema **caminha para trás no grafo** procurando o pré-requisito mal consolidado. Em vez de insistir em Logaritmo, o app diz:

> "Seus erros em *Logaritmo* apontam para uma lacuna em *Potenciação*. Vamos voltar um passo."

Isso é algo que nenhum dos dois modelos preditivos consegue fazer sozinho.

**b) Trilha de estudo / caminho mais curto**
O aluno define um objetivo ("quero dominar *Integrais*") e o app calcula o **caminho** partindo do que ele já domina até o alvo, respeitando a ordem de pré-requisitos. Custo de cada aresta = esforço estimado (nº de questões, complexidade, proficiência atual).

**c) Ordem válida de estudo**
Uma **ordenação topológica** do subgrafo relevante garante que a fila nunca ofereça um assunto cujo pré-requisito ainda está vermelho.

**d) Propagação do esquecimento**
Esquecer um assunto contamina os que dependem dele. Se *Potenciação* cai para o vermelho, a retenção estimada de *Logaritmo* também deve cair, mesmo sem tempo ter passado. Isso é uma propagação ponderada pelas arestas.

**e) Identificação de gargalos**
Assuntos com **alto grau de saída** (muitos dependentes) são pontos críticos: falhar neles trava várias frentes. O app prioriza esses vértices na fila e destaca para o aluno.

**f) Mapa de conhecimento visual (tela do app)**
O grafo renderizado na interface, com cada vértice colorido pela saúde da memória (verde / amarelo / vermelho). O aluno vê literalmente o mapa do que sabe, do que está esquecendo e do que ainda não abriu. É a tela mais vendável da apresentação.

### Algoritmos previstos
| Uso | Algoritmo |
|---|---|
| Diagnóstico de lacuna (caminhar para trás) | BFS / DFS reversa |
| Ordem válida de estudo | Ordenação topológica |
| Trilha até um objetivo | Dijkstra (arestas ponderadas por esforço) |
| Propagação de esquecimento | Travessia ponderada a partir do vértice afetado |
| Gargalos / assuntos críticos | Grau de saída, centralidade |
| Validação do grafo | Detecção de ciclos (o grafo de pré-requisitos deve ser um DAG) |
| Áreas isoladas do conhecimento | Componentes conexos |

### Custo real dessa decisão
O grafo precisa ser **construído e curado manualmente** — alguém do grupo tem que sentar e mapear os assuntos e suas dependências. Isso é trabalho de conteúdo, não de código, e é o principal risco de prazo deste pilar. Mitigação: começar com **uma única matéria** e poucas dezenas de vértices no MVP.

> `⬜ EM ABERTO` — representação do grafo (lista de adjacência? matriz? biblioteca de grafos?), persistência, matéria escolhida para o MVP e critério de atribuição dos pesos.

---

## 6. Como os três pilares se conectam

Esse é o diferencial do projeto: os componentes não são features soltas, eles alimentam **uma única fila de estudo**.

```
┌──────────────────────────────────────────────────────────┐
│                  FILA DE ESTUDO DO DIA                    │
├──────────────────────────────────────────────────────────┤
│                                                           │
│   GRAFO DE CONHECIMENTO                                   │
│   → define o que é elegível e em que ordem                │
│   → aponta a causa-raiz dos erros                         │
│                        │                                  │
│         ┌──────────────┴──────────────┐                   │
│         ▼                             ▼                   │
│   Previsor de Esquecimento      Recomendação Adaptativa   │
│   "o que está prestes a sumir?" "qual o próximo passo?"   │
│   → injeta REVISÕES             → injeta CONTEÚDO NOVO    │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

Leitura do fluxo:
1. O **grafo** filtra o universo de assuntos possíveis (só entra o que tem pré-requisito consolidado) e sinaliza lacunas.
2. O **previsor de esquecimento** marca, dentro desse conjunto, o que está em risco → vira revisão.
3. A **recomendação adaptativa** escolhe as questões concretas no nível certo → vira conteúdo novo.
4. O aluno vê apenas uma sessão de estudo coerente, sem saber que três sistemas negociaram aquilo.

> `⬜ EM ABERTO` — regra de proporção entre revisão, conteúdo novo e correção de lacuna (ex.: lacuna de pré-requisito sempre tem prioridade máxima? limite de itens por sessão?).

---

## 7. Funcionalidades do App

### 7.1 Essenciais (escopo mínimo da entrega)

**Autenticação e perfil**
- Cadastro e login
- Seleção de matérias/áreas de interesse
- Perfil com nível estimado por assunto

**Tela inicial (Home)**
- Barra de saúde da memória por assunto
- Alertas de itens em risco de esquecimento
- Aviso de lacuna de pré-requisito detectada pelo grafo
- Botão principal: iniciar sessão de estudo do dia

**Sessão de estudo**
- Fila montada pelos três pilares
- Responder questão → feedback imediato (certo/errado)
- Explicação da resposta
- Registro do resultado (realimenta os modelos e o grafo)

**Mapa de conhecimento**
- Visualização do grafo de assuntos
- Vértices coloridos por saúde da memória
- Toque no vértice → detalhes, pré-requisitos e ação de estudo

**Trilha até um objetivo**
- Aluno escolhe um assunto-alvo
- App calcula e exibe o caminho de estudo a partir do que ele já domina

**Banco de questões**
- Questões organizadas por matéria, assunto e nível
- Cada questão vinculada a um vértice do grafo

**Histórico e estatísticas**
- Desempenho por matéria e por assunto
- Evolução ao longo do tempo
- Pontos fortes e gargalos identificados

**Agenda de revisões**
- Lista do que revisar hoje / esta semana, ordenada por urgência

### 7.2 Desejáveis (se sobrar tempo)

- Notificações push no momento previsto de esquecimento
- Modo offline com sincronização posterior
- Gamificação: streak, XP, conquistas por "região do mapa" conquistada
- Simulados completos com correção e diagnóstico via grafo
- Flashcards do próprio aluno entrando no mesmo sistema de revisão
- Comparação anônima de progresso com outros alunos

### 7.3 Fora de escopo (explicitamente)

- Criação de conteúdo por professores (o painel administrativo do RF11 é de uso interno do grupo, não aberto a professores)
- Chat ou rede social entre alunos
- Videoaulas ou material teórico extenso
- Monetização / pagamentos
- Construção automática do grafo por IA (o grafo é curado à mão no MVP)

---

## 8. Requisitos

Requisitos consolidados para a apresentação. Escritos em linguagem de usuário, não de implementação.

### 8.1 Restrições do projeto

- Desenvolvimento obrigatório em Flutter
- Entrega como aplicação móvel
- Uso obrigatório de componente de IA

### 8.2 Requisitos Funcionais (RF)

| ID | Descrição |
|---|---|
| RF01 | Cadastrar e autenticar o aluno |
| RF02 | Permitir escolher a matéria de estudo (ou estudo geral) |
| RF03 | Montar a fila de estudo do dia automaticamente |
| RF04 | Exibir questões e registrar se o aluno acertou ou errou |
| RF05 | Mostrar a explicação da resposta após cada questão |
| RF06 | Ajustar a dificuldade das próximas questões conforme o desempenho |
| RF07 | Indicar quanto o aluno ainda lembra de cada assunto (painel de esquecimento) |
| RF08 | Avisar quando um assunto precisa de revisão e permitir iniciar uma sessão focada só no que está esquecendo |
| RF09 | Apontar o assunto anterior (pré-requisito) que está causando os erros |
| RF10 | Apresentar o histórico de desempenho por matéria e assunto |
| RF11 | Acessar painel de administrador para gerenciar matérias, assuntos, dependências do grafo e cadastrar questões |

### 8.3 Requisitos Não Funcionais (RNF)

| ID | Descrição |
|---|---|
| RNF01 | O aplicativo mobile deve ser desenvolvido em Flutter |
| RNF02 | A fila de estudo deve ser montada em até 2 segundos |
| RNF03 | O feedback da resposta e a explicação devem aparecer imediatamente |
| RNF04 | O app deve funcionar sem conexão com a internet (offline-first) |
| RNF05 | A interface deve ser simples, com o fluxo principal acessível em no máximo 3 toques |
| RNF06 | O mapa de assuntos deve rolar e ampliar sem travar |

### 8.4 Rastreabilidade — requisito x pilar

| Requisito | Pilar que atende |
|---|---|
| RF03, RF06 | Pilar 1 — Recomendação Adaptativa |
| RF07, RF08 | Pilar 2 — Previsor de Esquecimento |
| RF09 | Pilar 3 — Grafo de Conhecimento |
| RF01, RF02, RF04, RF05, RF10, RF11 | Base do app |

> `⬜ EM ABERTO` — não há RF cobrindo o **mapa de conhecimento** (seção 7.1), embora o RNF06 pressuponha essa tela. Decidir: entra como RF12 ou sai do escopo junto com o RNF06?

> `⬜ EM ABERTO` — não há RF cobrindo a **trilha até um objetivo** (seção 7.1). Provável adiamento pós-MVP; confirmar e registrar.

> `⬜ EM ABERTO` — o RNF04 (offline-first) implica decidir onde os modelos rodam e como o grafo é persistido no dispositivo. Ver seção 10.

---

## 9. Entidades principais

Modelo de dados consolidado. Nomes em português sem acento, para casar com o código.

### 9.1 Tabelas

| Tabela | Campos | Função |
|---|---|---|
| **Usuario** | `id`, `nome`, `email`, `senha`, `tipo` | Separa aluno de admin (RF01, RF11) |
| **Materia** | `id`, `nome` | Filtro principal do app (RF02) |
| **Assunto** | `id`, `id_materia`, `nome`, `descricao` | Tópicos de estudo e vértices do grafo |
| **Grafo_Dependencia** | `id_prerequisito`, `id_dependente`, `peso` | Arestas do grafo — permite achar a causa do erro (RF09) |
| **Questao** | `id`, `id_assunto`, `enunciado`, `explicacao`, `dificuldade` | Conteúdo da fila (RF04, RF05) |
| **Alternativa** | `id`, `id_questao`, `letra`, `texto`, `correta` | Opções de resposta e gabarito (RF04) |
| **Historico_Estudo** | `id`, `id_usuario`, `id_questao`, `acertou`, `data`, `tempo_gasto` | Evento que calibra a dificuldade (RF06) |
| **Nivel_Memoria** | `id_usuario`, `id_assunto`, `retencao_atual`, `data_ultimo_estudo`, `qtd_revisoes` | Alimenta o painel de esquecimento e os avisos (RF07, RF08) |
| **Proficiencia** | `id_usuario`, `id_assunto`, `nivel_estimado`, `data_atualizacao` | Nível estimado do aluno por assunto (RF06) |

### 9.2 Decisões de modelagem

**Alternativas em tabela separada.** Uma questão tem várias alternativas — guardar todas num campo só seria atributo multivalorado e violaria a 1FN. O gabarito é o campo `correta` da `Alternativa`, não um campo na `Questao`, para evitar redundância. O campo `letra` garante a ordem de exibição.

**Chaves compostas.** `Grafo_Dependencia` usa `id_prerequisito` + `id_dependente` (impede aresta duplicada). `Nivel_Memoria` e `Proficiencia` usam `id_usuario` + `id_assunto`.

**Direção da aresta.** Lê-se sempre `id_prerequisito` → `id_dependente`. Nomes escolhidos para eliminar ambiguidade nas travessias.

**Duas leituras do grafo, colunas opostas.** RF09 (causa-raiz) busca por `id_dependente` para caminhar para trás. A propagação do esquecimento busca por `id_prerequisito` para caminhar para frente. Índice nas duas colunas.

**Validação de ciclo é responsabilidade do app.** O banco aceita A→B→C→A sem reclamar; o painel administrativo (RF11) precisa checar antes de salvar, senão a travessia entra em loop.

**Campo `senha`.** Nome da coluna conforme convenção de modelagem, mas o valor armazenado deve ser o hash da senha, nunca o texto puro.

> `⬜ EM ABERTO` — manter `Nivel_Memoria` e `Proficiencia` separadas ou fundir numa tabela só? Mesma chave, conceitos diferentes (o quanto lembra x o quão bom é).

> `⬜ EM ABERTO` — criar tabela `Sessao_Estudo`? Só faz falta se o histórico agrupado por dia for aparecer na interface. `Historico_Estudo` sozinho já atende o RF10.

> `⬜ EM ABERTO` — número de alternativas por questão é fixo (5, padrão ENEM) ou variável?

---

## 10. Arquitetura em alto nível

```
┌──────────────────┐
│   App Flutter    │   Interface, fila de estudo, mapa de conhecimento
└────────┬─────────┘
         │
┌────────▼─────────┐
│      Backend     │   Autenticação, questões, histórico, grafo
└────────┬─────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐ ┌──────────────┐
│  IA    │ │    Grafo     │
│ 2 mod. │ │ travessias e │
│        │ │  algoritmos  │
└────────┘ └──────────────┘
```

> `⬜ EM ABERTO` — backend, banco de dados, onde os algoritmos de grafo rodam (cliente ou servidor?), forma de servir os modelos e hospedagem.

---

## 11. Decisões em aberto (checklist)

**Produto**
- [ ] Nome do app
- [ ] Público-alvo definitivo (vestibular? graduação? ambos?)
- [ ] Matéria(s) contemplada(s) no MVP
- [ ] Origem do banco de questões (autoral? base pública? geradas?)

**Grafo**
- [ ] Matéria escolhida para o grafo do MVP
- [ ] Quantidade de vértices no MVP
- [ ] Quem curará as dependências entre assuntos
- [ ] Critério de peso das arestas
- [ ] Representação e persistência do grafo
- [ ] Quais algoritmos entram no MVP e quais ficam para depois

**IA**
- [ ] Algoritmo do Pilar 1
- [ ] Algoritmo do Pilar 2
- [ ] Estratégia de geração dos datasets sintéticos
- [ ] Métricas de avaliação dos modelos
- [ ] Como os modelos são servidos ao app

**Técnico**
- [ ] Backend e banco de dados
- [ ] Gerenciamento de estado no Flutter
- [ ] Biblioteca de visualização do grafo em Flutter
- [ ] Divisão de tarefas entre os integrantes

---

## 12. Critérios de sucesso do projeto

O projeto é considerado bem-sucedido se:

1. O app roda em dispositivo móvel e completa o fluxo: login → home com saúde da memória → sessão de estudo → registro do resultado → atualização da recomendação
2. Os dois modelos estão treinados, avaliados e efetivamente influenciando o que o aluno vê
3. O grafo está implementado com algoritmos reais de travessia — não apenas desenhado na tela — e influencia a fila de estudo
4. A recomendação demonstra adaptação: dois alunos com históricos diferentes recebem filas diferentes
5. O diagnóstico de causa-raiz funciona: o app consegue apontar um pré-requisito falho a partir de erros em um assunto avançado
6. O mapa de conhecimento é navegável e reflete o estado real do aluno
7. É possível explicar e defender as escolhas técnicas na apresentação

---

## 13. Glossário

**Aprendizagem adaptativa** — abordagem em que o conteúdo se ajusta ao desempenho individual do estudante em tempo real.

**Curva de esquecimento** — modelo que descreve como a retenção de uma informação decai com o passar do tempo sem reforço.

**Repetição espaçada** — técnica de estudo que agenda revisões em intervalos crescentes, sempre próximo ao ponto de esquecimento.

**Grafo de conhecimento** — representação dos assuntos como vértices e das relações de pré-requisito como arestas direcionadas.

**DAG** — grafo direcionado acíclico. O grafo de pré-requisitos precisa ser um DAG: se houver ciclo, existe uma dependência circular impossível de estudar.

**Ordenação topológica** — sequência linear dos vértices de um DAG em que todo pré-requisito aparece antes de seus dependentes.

**Gargalo** — assunto com muitos dependentes; falhar nele bloqueia vários caminhos de estudo.

**Dataset sintético** — base de dados gerada artificialmente para treinar modelos quando não há dados reais disponíveis.

**Zona de dificuldade ideal** — faixa em que a tarefa é desafiadora o bastante para gerar aprendizado, sem ser frustrante a ponto de causar desistência.

---

*Última atualização: 26/08/2026*
