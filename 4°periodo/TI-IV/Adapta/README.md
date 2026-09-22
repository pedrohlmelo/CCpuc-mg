# Adapta

App mobile (Flutter) de estudo por questões que **decide pelo aluno o que estudar agora**.
Trabalho Interdisciplinar IV.

Esta entrega é um **protótipo de telas e navegação**: nenhuma funcionalidade está
implementada no app. Não há banco de dados, autenticação nem algoritmo de estudo — isso é
trabalho do backend **Java + Spring** (repositório separado, a criar). As telas usam dados
de exemplo fixos, em memória.

> Fonte de verdade do projeto: [`docs/memoria.md`](docs/memoria.md).
> Onde fica cada tela: [`docs/TELAS.md`](docs/TELAS.md).
> Mapa do código: [`docs/ESTRUTURA.md`](docs/ESTRUTURA.md).
> Modelagem e decisões técnicas: [`docs/MODELAGEM.md`](docs/MODELAGEM.md).

## Rodar

```bash
flutter pub get
flutter run          # emulador / dispositivo
flutter test         # navegação, dados de exemplo e tema
flutter analyze
```

O app abre direto na tela inicial do aluno. Não há tela de login na abertura: entrar e
criar conta ficam na aba **Perfil**, junto com o acesso ao painel administrativo.

## Telas

**Aluno:** inicial, escolher matéria, sessão de estudo, histórico de estudo, resolução de
uma questão antiga e perfil.
**Conta:** entrar e criar conta.
**Painel administrativo:** menu, matérias, assuntos, grafo de dependências e questões.

Navegação: três abas na base (Início, Histórico, Perfil); as demais telas abrem por cima e
sempre têm botão de voltar.

## Identidade

Mascote **Camu** (camaleão) e ícone do app configurados para Android e iOS. Tema claro e
escuro, fonte Plus Jakarta Sans embarcada (funciona offline).

Capturas de tela para slides:

```bash
CAPTURAS=1 flutter test test/capturas --tags capturas   # gera capturas/*.png
```

## Próximo passo

Criar o backend e trocar `lib/dados/dados_exemplo.dart` por chamadas de API. As telas não
precisam mudar para isso: nenhuma delas conhece a origem dos dados.

---

© 2026 Adapta. Todos os direitos reservados.
