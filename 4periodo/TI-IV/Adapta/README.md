# Adapta

App Flutter de estudos para o ENEM (Trabalho Interdisciplinar IV, PUC Minas). A
fila de questões se adapta a cada aluno: um modelo prevê o que está sendo
esquecido, outro estima a proficiência, e um grafo de pré-requisitos encontra a
causa das dificuldades. Funciona 100% offline.

## Tecnologias

- **Flutter**, com `go_router` (navegação) e `flutter_riverpod` (estado)
- **SQLite** (`sqflite`): fonte de verdade no aparelho
- **Shared Preferences**: só configurações
- **Firebase**: Authentication (e-mail/senha e anônimo) e Cloud Firestore (cópia do progresso)
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
dart run ferramentas/exportar_seed.dart
python3 ia/gerar_dataset.py
python3 ia/treinar.py
```

Atualiza `assets/modelos/`, `ia/relatorio.md` e os gráficos. As figuras das
questões saem de `python3 ferramentas/gerar_figuras_seed.py`.
