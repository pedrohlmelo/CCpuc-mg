# Pilar 2 — Previsor da Curva de Esquecimento

Classificação binária: dado `[dias_desde_ultimo_estudo, complexidade, qtd_revisoes]`,
o aluno vai lembrar ou esquecer? Alimenta a barra de saúde da memória
(consolidado / em risco / crítico) e os alertas de revisão (RF07, RF08).

Hoje: `PrevisorExponencialFixo` (stub — curva fixa igual para todo aluno, como o Anki).

Em aberto (memória, seção 4): algoritmo, features finais, calibração, dataset sintético de
sessões de revisão. Trocar a implementação em `previsorEsquecimentoProvider`.
