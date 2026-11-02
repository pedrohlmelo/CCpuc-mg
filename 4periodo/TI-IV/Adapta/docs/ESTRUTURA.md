# Estrutura do código

O app desta etapa é um **protótipo de telas e navegação**: sem banco, sem rede e sem
regra de estudo. As pastas são organizadas por tipo de arquivo, não por funcionalidade,
para que achar uma tela seja imediato.

```
lib/
├── main.dart                     sobe o app (só lê a preferência de tema)
├── app.dart                      MaterialApp.router + tema
├── telas/                        TODAS as telas ficam aqui — ver docs/TELAS.md
│   ├── aluno/                    inicial, matérias, sessão, histórico, resolução, perfil
│   ├── auth/                     login, cadastro e a moldura das duas
│   └── admin/                    painel: menu, matérias, assuntos, grafo, questões
├── navegacao/
│   ├── rotas.dart                mapa de rotas (go_router)
│   └── casca_aluno.dart          barra inferior: Início, Histórico, Perfil
├── dados/
│   ├── modelos.dart              classes simples que as telas desenham
│   ├── dados_exemplo.dart        listas fixas de matérias, assuntos, questões e histórico
│   └── estado_prototipo.dart     estado em memória: aba, matéria, nome, respostas
├── tema/
│   ├── app_tema.dart             tokens (AppCores, CoresMemoria, AppMedidas) e tipografia
│   └── tema_controller.dart      claro/escuro, salvo em shared_preferences
└── widgets/                      peças reutilizadas pelas telas
    ├── cartoes.dart              AppCartao, CartaoGradiente, TileEstatistica, BarraSaude…
    ├── questao_widget.dart       enunciado + alternativas + feedback (e modo leitura)
    ├── botao_voltar.dart         volta uma tela, ou vai para o início se não houver
    ├── botao_tema.dart           ícone sol/lua
    ├── saude_memoria.dart        cor, rótulo e legenda dos estados de memória
    ├── formato_data.dart         "Hoje", "Ontem", "20 de set", "09:12"
    ├── mascote.dart              Camu (normal / feliz / pensativo)
    ├── marca.dart                logotipo "Adapta•"
    ├── paleta_materias.dart      ícone e cor por matéria
    └── rodape_copyright.dart     linha de copyright

assets/
├── mascote/                      camu_normal / camu_feliz / camu_pensativo (PNG)
├── icone/                        fontes do ícone do app (flutter_launcher_icons)
└── fontes/                       Plus Jakarta Sans (OFL)

test/
├── widget/navegacao_test.dart    as telas abrem, voltam e registram respostas
├── widget/tema_toggle_test.dart  alternância de tema
├── dados/dados_exemplo_test.dart coerência dos dados de exemplo
└── capturas/                     gera PNGs das telas (ver README)
```

## O que ficou fora do app, de propósito

Banco de dados, autenticação, montagem da fila de estudo e os três pilares
(recomendação, esquecimento e grafo) são responsabilidade do **backend Java + Spring**,
ainda a ser criado. Ver `docs/memoria.md`, seção 10.1.

Enquanto ele não existe, as telas leem `lib/dados/dados_exemplo.dart`. A integração
futura troca esse arquivo por chamadas de API sem alterar as telas.

## Identidade visual

- Mascote: **Camu**, um camaleão (adaptação = a proposta do app). PNGs em `assets/mascote/`.
- Marca: índigo `#4F46E5` → violeta `#7C3AED`. Camu em teal `#14B8A6` → lima `#A3E635`.
- Saúde da memória: verde / âmbar / vermelho fixos (`CoresMemoria`), iguais nos dois temas.
- Tipografia: Plus Jakarta Sans, títulos com peso 700–800 e tracking negativo.
- Superfícies: cartões com borda fina de 1px, raio 20, sem elevação.

Para regenerar mascote e ícone: script em `docs/mascote.py`; ícones com
`dart run flutter_launcher_icons`.

## Convenções

- Nomes em português sem acento no código; acentos só em strings de interface.
- Tela nova: seguir o passo a passo no fim de `docs/TELAS.md`.
- Nenhum widget conhece SQL, HTTP ou regra de negócio. Dados vêm de `lib/dados/`.
- Cada `Scaffold` de tela tem a chave `Key('tela_<nome>')`, usada pelos testes.
