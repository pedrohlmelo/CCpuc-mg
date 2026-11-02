# Scripts de conteúdo

O Firestore é a única fonte do conteúdo. O caminho é:
API enem.dev → estes scripts → Firestore → pacote inicial em Dart → SQLite do aparelho.

## Preparação

```sh
python3 -m venv ~/.venvs/adapta && source ~/.venvs/adapta/bin/activate
pip install -r ferramentas/conteudo/requirements.txt
export GOOGLE_APPLICATION_CREDENTIALS=/caminho/fora/do/repositorio/chave.json
```

A chave vem do console (Configurações do projeto → Contas de serviço → Gerar nova chave
privada). Nunca coloque esse arquivo no repositório. Todo script que grava aceita `--simular`;
sem credencial, ele simula contra um Firestore vazio.

Para testar sem tocar no projeto real, use o emulador, que dispensa a chave:

```sh
firebase emulators:start --only firestore --project demo-adapta
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-adapta
```

## Ordem

| Script | O que faz |
|---|---|
| `estrutura.py` | Grava matérias, assuntos e arestas, definidos no próprio script |
| `autorais.py` | Grava as questões autorais, definidas no próprio script |
| `importar_enem.py 2023 2022` | Grava as provas como questões inativas e sem assunto |
| `classificar.py pendentes` | Mostra as próximas questões sem assunto |
| `classificar.py aplicar notas.json` | Grava matéria, assunto, confiança e explicação e ativa |
| `revisao.py exportar` / `aplicar revisao.csv` | Revisão do grupo por planilha |
| `relatorio.py` | Contagens por matéria e assunto, regras de ids e DAG |
| `gerar_pacote_inicial.py` | Gera `lib/dados/banco/pacote_inicial.g.dart`; rode antes de cada build |

Rodar de novo é seguro: questão que já existe não é sobrescrita pela importação nem por
`autorais.py`, e `classificar.py` só toca questão ainda sem assunto. Todo script que muda conteúdo
sobe `versao` em `meta/conteudo` por último.

## API enem.dev

Especificação em `https://api.enem.dev/v1`.

- `GET /v1/exams`: lista as provas.
- `GET /v1/exams/{ano}/questions?limit=50&offset=N&language=ingles|espanhol`: no máximo 50 por
  página. Devolve `questions` e `metadata.hasMore`. Responde 429 quando passa do limite de
  requisições, e o script espera e tenta de novo.
- `GET /v1/exams/{ano}/questions/{indice}`: uma questão.

Campos usados de cada questão: `year`, `index`, `language`, `discipline`, `context` (Markdown, com
imagens), `files`, `alternativesIntroduction`, `correctAlternative` e `alternatives`, cada uma com
`letter`, `text`, `file` e `isCorrect`. A API traz só a área: matéria e assunto são classificados
depois.

Ficam de fora: questão sem gabarito ou sem 5 alternativas, com gabarito inconsistente, com imagem
ausente na API (`broken-image`) ou que não responde ao `HEAD`, e com mais de uma imagem no enunciado.
