# Importação das questões do ENEM

As questões reais vêm da API pública [enem.dev](https://enem.dev). O app **nunca**
chama essa API: ela só é usada aqui, para gerar os JSON de `assets/conteudo/`.

## A API

Consultada em 02/11/2026. A especificação OpenAPI 3.0.3 sai em `GET https://api.enem.dev/v1`.

| Rota | O que devolve |
|---|---|
| `GET /v1/exams` | Provas: `title`, `year`, `disciplines[]`, `languages[]` |
| `GET /v1/exams/{ano}/questions?limit=50&offset=0&language=ingles` | `metadata` (`limit`, `offset`, `total`, `hasMore`) e `questions[]`; no máximo 50 por página |
| `GET /v1/exams/{ano}/questions/{indice}` | Uma questão |

Campos de cada questão: `title`, `index`, `discipline`, `language`, `year`, `context`
(Markdown, com imagens embutidas), `files[]`, `correctAlternative`,
`alternativesIntroduction` e `alternatives[]` (`letter`, `text`, `file`, `isCorrect`).

`language` vale `ingles` ou `espanhol` nas questões 1 a 5 e nulo nas demais.

## O que é preciso saber sobre os dados

- `discipline` não é confiável: há questão de Humanas com índice 154. A matéria e o
  assunto saem da leitura do texto, em `classificacao.json`.
- Imagem perdida aparece como `https://enem.dev/broken-image.svg`. A questão fica de fora.
- Fórmulas podem se perder na extração, como `√28` que virou `28` na questão 161 de
  2023. Correções seguras ficam em `CORRECOES`, no `montar.py`.
- Há questões sem o texto-base ou com alternativas repetidas. Elas ficam com
  `"assunto": null` em `classificacao.json`, e por isso não entram no app.

## Como rodar

```sh
python3 ferramentas/importar_enem/importar.py 2023 2022   # baixa e converte (usa o cache)
python3 ferramentas/importar_enem/montar.py               # grava assets/conteudo/ e revisao.csv
python3 ferramentas/relatorio_conteudo.py                 # resume e confere as regras
```

Requer macOS, porque as imagens são convertidas com o `sips`. Ano novo exige declarar
a pasta `assets/questoes/enem/{ano}/` no `pubspec.yaml`.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `assuntos.json` | Matérias, assuntos novos e arestas do grafo |
| `questoes_brutas.json` | Questões convertidas e motivo de quem ficou de fora |
| `classificacao.json` | Assunto e confiança de cada questão. `null` fica de fora do app |
| `explicacoes.json` | Explicações escritas para as questões importadas |
| `autorais.json` | Questões autorais que completam assuntos com menos de 3 questões |
| `revisao.csv` | O que falta revisar, com confiança baixa primeiro |

## Revisão do grupo

Depois de conferir assunto, gabarito e explicação, marque `"revisado": true` na questão
em `assets/conteudo/`. Rodar `montar.py` de novo mantém o texto das questões revisadas.
Para mudar o assunto, altere `classificacao.json` e rode o script.
