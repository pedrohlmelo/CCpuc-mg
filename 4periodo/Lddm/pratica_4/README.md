# pratica_9

Diário de Hábitos: Aula 09, Persistência Local (Atividade Prática 4).
Cópia do `check_2`, agora com os dados sobrevivendo ao fechar o aplicativo.

## A: a lista vai para o SQLite

- `lib/dominio/habito.dart`: o modelo ganhou `id` e os métodos `toMap()` / `Habito.fromMap()`.
- `lib/dados/habitos_repositorio.dart`: usa `sqflite` (tabela `habitos`) com `carregar`, `salvar`, `atualizar` e `apagar`.
- A interface e a loja não mudaram a forma de pedir o dado. Só o repositório trocou de memória para SQLite.

## B: uma preferência vai para o shared_preferences

- `lib/dados/preferencias.dart`: `salvarTema` / `lerTema` (chave `tema_escuro`).
- O tema é lido no `main` antes do `runApp`, e o switch "Tema escuro" fica na aba Resumo.

## C: por que cada dado foi para onde foi

1. A lista de hábitos foi para o SQLite porque tem muitos registros iguais (id, nome, meta), que precisam ser buscados, alterados e apagados um a um.
2. O tema escuro foi para o shared_preferences porque é um único valor de configuração, que cabe numa linha de chave e valor.
3. O shared_preferences não é banco de dados: ele lê tudo de uma vez para a memória, então a lista lá funcionaria com dez itens e quebraria com mil.

## Declaração de uso de IA

<!-- Revise e ajuste: a escolha da preferência e o motivo precisam ser seus. -->
Usei IA (Claude) para apoiar a implementação do SQLite e do shared_preferences seguindo o material da Aula 09.

## Como testar

O `sqflite` roda em Android, iOS e macOS, mas não no navegador. Cadastre hábitos e feche o app **de verdade**, porque a recarga a quente não reinicia o processo. Depois reabra.

```
flutter pub get
flutter run
flutter test
```
