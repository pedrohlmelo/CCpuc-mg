# Mapa de telas

Onde está cada tela do Adapta. Todas ficam em `lib/telas/`, uma pasta por público.

## Aluno — `lib/telas/aluno/`

| Tela | Arquivo | Rota | Como se chega |
|---|---|---|---|
| Inicial do aluno | `home_screen.dart` | `/` | abre o app |
| Histórico de estudo | `historico_screen.dart` | `/historico` | aba "Histórico" ou atalho na inicial |
| Resolução de uma questão | `historico_detalhe_screen.dart` | `/historico/:idQuestao` | tocar num item do histórico |
| Escolher matéria | `materias_screen.dart` | `/materias` | chip da matéria na inicial |
| Sessão de estudo | `sessao_screen.dart` | `/sessao` | botão "Estudar agora" |
| Refazer uma questão | `sessao_screen.dart` | `/sessao?questao=:id` | botão "Refazer questão" na resolução |
| Perfil | `perfil_screen.dart` | `/perfil` | aba "Perfil" |

## Conta — `lib/telas/auth/`

| Tela | Arquivo | Rota | Como se chega |
|---|---|---|---|
| Entrar | `login_screen.dart` | `/login` | Perfil → Entrar |
| Criar conta | `cadastro_screen.dart` | `/cadastro` | Perfil → Criar conta |
| Moldura das duas | `moldura_auth.dart` | — | cabeçalho com gradiente e mascote |

O app **não abre em tela de login**. Dá para estudar sem conta.

## Painel administrativo — `lib/telas/admin/`

| Tela | Arquivo | Rota |
|---|---|---|
| Menu do painel | `admin_home_screen.dart` | `/admin` |
| Matérias | `admin_materias_screen.dart` | `/admin/materias` |
| Assuntos | `admin_assuntos_screen.dart` | `/admin/assuntos` |
| Grafo de dependências | `admin_grafo_screen.dart` | `/admin/grafo` |
| Questões | `admin_questoes_screen.dart` | `/admin/questoes` |
| Moldura das internas | `admin_scaffold.dart` | — |

Chega-se ao painel por Perfil → Painel administrativo.

## Navegação

- Três abas fixas na base: **Início**, **Histórico** e **Perfil** (`lib/navegacao/casca_aluno.dart`).
- As demais telas abrem por cima das abas e **sempre têm botão de voltar**
  (`lib/widgets/botao_voltar.dart`), que cai na tela inicial se não houver histórico de
  navegação.
- O mapa completo de rotas está em `lib/navegacao/rotas.dart`.

## Convenção para uma tela nova

1. Criar o arquivo em `lib/telas/<publico>/<nome>_screen.dart`.
2. Dar ao `Scaffold` a chave `Key('tela_<nome>')`, que é o que os testes de navegação usam.
3. Registrar a rota em `lib/navegacao/rotas.dart`.
4. Se a tela abrir por cima das abas, usar `BotaoVoltar` no `leading` da `AppBar`.
5. Acrescentar a linha correspondente neste arquivo.
