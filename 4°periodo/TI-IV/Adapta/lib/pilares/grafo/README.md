# Pilar 3 — Grafo de Conhecimento

Vértices = `Assunto`, arestas = `Grafo_Dependencia` (`prerequisito → dependente`, peso).

Já implementado em `grafo_conhecimento.dart`:
- lista de adjacência dupla (saída / entrada)
- detecção de ciclo (`criariaCiclo`, `ehDag`) — usada pelo painel admin antes de salvar aresta
- ordenação topológica (Kahn)
- pré-requisitos transitivos (BFS reversa) — base do diagnóstico de causa-raiz (RF09)
- grau de saída — base para gargalos

Próximas sprints:
- Dijkstra para trilha até um objetivo (custo = esforço estimado)
- propagação ponderada do esquecimento
- componentes conexos
- integração com `Nivel_Memoria` para colorir o mapa
