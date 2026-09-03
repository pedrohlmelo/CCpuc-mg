# Adapta

App mobile (Flutter) de estudo por questões que **decide pelo aluno o que estudar agora**.
Trabalho Interdisciplinar IV.

Stack: app **Flutter/Dart**; backend **Java + Spring** (repositório separado, a criar).
Não há código Kotlin no app: `android/` é só a casca gerada pelo Flutter, com `MainActivity.java`.

> Fonte de verdade do projeto: [`docs/memoria.md`](docs/memoria.md).
> Modelagem derivada e decisões técnicas: [`docs/MODELAGEM.md`](docs/MODELAGEM.md).
> Mapa do código: [`docs/ESTRUTURA.md`](docs/ESTRUTURA.md).

## Rodar

```bash
flutter pub get
flutter run          # emulador / dispositivo
flutter test         # testes unitários e de widget (SQLite em memória)
flutter analyze
```

Usuário administrador do seed: `admin@adapta.app` / `admin123`.
Alunos são criados pela tela "Criar conta".

## Identidade

Mascote **Camu** (camaleão) e ícone do app já configurados para Android e iOS.
Tema claro e escuro, fonte Plus Jakarta Sans embarcada (funciona offline).

Capturas de tela para slides:

```bash
CAPTURAS=1 flutter test test/capturas --tags capturas   # gera capturas/*.png
```

## Estado atual — Sprint 2

- [x] Projeto Flutter + banco local SQLite (9 tabelas da memória, seed)
- [x] Cadastro e autenticação com hash de senha (RF01)
- [x] Painel administrativo: matérias, assuntos, grafo (com validação de ciclo), listagem de questões (RF11)
- [x] Escolha de matéria ou estudo geral (RF02)
- [x] Tela de questão com feedback, explicação e registro no histórico (RF04, RF05)
- [x] Contratos dos três pilares com implementações provisórias (`lib/pilares/`)
- [x] Design system (tokens, tema claro/escuro, componentes), mascote e ícone

Próximas sprints: fila de estudo (RF03), adaptação de dificuldade (RF06), painel de
esquecimento (RF07/08), diagnóstico de causa-raiz (RF09), histórico (RF10), mapa do grafo.

---

© 2026 Adapta. Todos os direitos reservados.
