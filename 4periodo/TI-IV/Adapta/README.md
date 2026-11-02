# Adapta

App Flutter de estudos para o ENEM (Trabalho Interdisciplinar IV, PUC Minas). A
fila de questões se adapta a cada aluno: um modelo prevê o que está sendo
esquecido, outro estima a proficiência, e um grafo de pré-requisitos encontra a
causa das dificuldades. Cobre as 14 matérias do ENEM, menos Redação, com questões
reais das provas, e funciona offline depois de instalado.

## Tecnologias

- **Flutter**, com `go_router` (navegação) e `flutter_riverpod` (estado)
- **SQLite** (`sqflite`): fonte de verdade no aparelho
- **Shared Preferences**: só configurações
- **Firebase**: Authentication (e-mail/senha e anônimo) e Cloud Firestore (banco de questões e cópia do progresso)
- **Python** com scikit-learn: treino dos modelos, cuja inferência roda em Dart no aparelho

Não há backend próprio. Detalhes em
[`Documentacao/03-sprint3-armazenamento-ia-grafos.md`](Documentacao/03-sprint3-armazenamento-ia-grafos.md).

## Rodar o app

```
flutter pub get
flutter run
```

Sem a configuração do Firebase o app abre normalmente, só com o SQLite: dá para
estudar como visitante, mas não para criar conta nem sincronizar.

## Configurar o Firebase

1. No [console do Firebase](https://console.firebase.google.com), crie um projeto no plano Spark.
2. Ative **Authentication** com **E-mail/senha** e **Anônimo**, e crie o **Cloud Firestore**.
3. Na raiz deste projeto:
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   firebase use --add
   firebase deploy --only firestore:rules
   ```
4. Crie no console uma conta com e-mail e senha e o documento `usuarios/{uid}` com
   `tipo: "admin"`, `nome` e `email`.

## Conteúdo

O Firestore é a única fonte do conteúdo: API enem.dev → scripts → Firestore → pacote
inicial em Dart → SQLite do aparelho. O app nunca chama a API. Os scripts ficam em
[`ferramentas/conteudo/`](ferramentas/conteudo/README.md). Rode
`gerar_pacote_inicial.py` antes de cada build para o pacote sair atualizado.

## Testes

```
flutter test
dart analyze .
```

Os testes não usam internet nem o Firebase real. Em pastas com caracteres como
`°` no caminho, o `flutter analyze` 3.44 quebra antes de analisar; use `dart analyze .`.

## Treinar os modelos

```
python3 -m pip install -r ia/requirements.txt
python3 ia/gerar_dataset.py
python3 ia/treinar.py
```

Lê as questões do Firestore, com a credencial de `ferramentas/conteudo/README.md`.
Atualiza `assets/modelos/esquecimento.json`, `ia/relatorio.md`, os gráficos e o campo
`dificuldade_irt` de cada questão. Depois, gere o pacote inicial de novo. As figuras das
questões autorais saem de `python3 ferramentas/gerar_figuras_seed.py`.
