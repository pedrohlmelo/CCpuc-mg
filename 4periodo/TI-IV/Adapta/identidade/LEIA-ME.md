# Identidade visual do Adapta

Mascote **Camu** (camaleão) e ícone do app. Todos os `.svg` são vetoriais e editáveis
(Figma, Illustrator, Inkscape). Os `.png` são exportações nos tamanhos indicados no nome.

| Arquivo | Uso |
|---|---|
| `icone_app_*` | ícone quadrado com fundo em gradiente (lojas, slides) |
| `icone_app_arredondado_*` | mesma arte com cantos arredondados (mockups, site) |
| `icone_foreground_adaptive_*` | camada frontal do adaptive icon Android (fundo `#4F46E5`) |
| `camu_normal_*` | mascote padrão, no galho |
| `camu_feliz_*` | acertou / boas-vindas |
| `camu_pensativo_*` | errou / estado vazio |
| `camu_sem_galho_*` | mascote solto, para compor em outras artes |

Cores: índigo `#4F46E5` → violeta `#7C3AED` (marca); teal `#14B8A6` → lima `#A3E635` (Camu).
Fonte: Plus Jakarta Sans.

Regenerar tudo: `python3 docs/mascote.py` (precisa de `rsvg-convert`, via `brew install librsvg`).
