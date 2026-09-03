# Estrutura do código

```
lib/
├── main.dart                        abre o banco e sobe o app com ProviderScope
├── app.dart                         MaterialApp.router + tema
├── core/
│   ├── database/
│   │   ├── tabelas.dart             DDL das 9 tabelas (seção 9 da memória)
│   │   ├── seed.dart                dados iniciais (admin, 2 matérias, grafo pequeno, questões)
│   │   └── app_database.dart        abrirBanco() + databaseProvider
│   ├── seguranca/hash_senha.dart    SHA-256 + salt
│   ├── router/app_router.dart       rotas + guarda de sessão/admin
│   ├── tema/app_tema.dart           tokens (AppCores, CoresMemoria, AppMedidas), tema claro/escuro, tipografia
│   └── widgets/                     componentes compartilhados
│       ├── mascote.dart             Camu (poses normal/feliz/pensativo) + versão animada
│       ├── marca.dart               logotipo "Adapta•"
│       ├── cartoes.dart             AppCartao, CartaoGradiente, TileEstatistica, BarraSaude, EstadoVazio…
│       └── paleta_materias.dart     ícone + cor por matéria
├── features/                        uma pasta por funcionalidade; domain / data / application / presentation
│   ├── autenticacao/                RF01 — Usuario, UsuarioRepository, SessaoController, login e cadastro
│   ├── materias/                    RF02 — Materia, Assunto, MateriaRepository, tela de escolha
│   ├── questoes/                    RF04/05 — Questao, Alternativa, HistoricoEstudo, repositórios, sessão
│   ├── home/                        tela inicial: resumo, saúde da memória (via previsor), alertas
│   └── admin/                       RF11 — GrafoRepository e telas do painel
└── pilares/                         contratos + stubs dos três motores
    ├── grafo/                       GrafoConhecimento (DAG, ciclo, topológica, BFS reversa)
    ├── recomendacao/                Recomendador (stub sequencial)
    └── esquecimento/                PrevisorEsquecimento (stub exponencial)

assets/
├── mascote/                         camu_normal / camu_feliz / camu_pensativo (PNG 768px)
├── icone/                           fontes do ícone do app (flutter_launcher_icons)
└── fontes/                          Plus Jakarta Sans (variável, OFL)

test/
├── test_helpers.dart                bancoDeTeste(): SQLite em memória com seed
├── capturas/                        gera PNGs das telas (CAPTURAS=1 flutter test test/capturas --tags capturas)
├── core/                            schema, seed, hash
├── features/                        repositórios
├── pilares/                         grafo e previsor
└── widget/                          fluxo completo login → matéria → questão
```

## Identidade visual

- Mascote: **Camu**, um camaleão (adaptação = a proposta do app). Vetor gerado por script; PNGs em `assets/mascote/`.
- Marca: índigo `#4F46E5` → violeta `#7C3AED`. Camu em teal `#14B8A6` → lima `#A3E635`.
- Saúde da memória: verde / âmbar / vermelho fixos (`CoresMemoria`), iguais nos dois temas.
- Tipografia: Plus Jakarta Sans, títulos com peso 700–800 e tracking negativo.
- Superfícies: cartões com borda fina de 1px, raio 20, sem elevação; sombra só em destaque.
- Tema escuro segue o sistema (`ThemeMode.system`).

Para regenerar mascote e ícone: script Python usado está em `docs/` (ver `mascote.py`); ícones com `dart run flutter_launcher_icons`.

## Convenções

- Nomes em português sem acento no código; acentos só em strings de interface.
- Tela nova = pasta em `features/<nome>/presentation/` + rota em `core/router/app_router.dart`.
- Acesso a banco só em `data/*_repository.dart`. Widgets nunca falam SQL.
- Cada repositório expõe um `Provider`; nos testes, sobrescreva `databaseProvider`.
- Trocar o algoritmo de um pilar = trocar a implementação no `Provider` correspondente.
