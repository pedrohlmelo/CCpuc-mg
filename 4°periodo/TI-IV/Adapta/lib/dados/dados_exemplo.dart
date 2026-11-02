/// Conteúdo inicial escrito à mão. É só fonte do seed: as telas leem do SQLite
/// (`banco/seed.dart` amplia estas listas e grava no banco).
library;

import 'modelos.dart';

const materiasExemplo = <Materia>[
  Materia(id: 1, nome: 'Matemática'),
  Materia(id: 2, nome: 'História'),
];

const assuntosExemplo = <Assunto>[
  Assunto(id: 1, idMateria: 1, nome: 'Potenciação'),
  Assunto(id: 2, idMateria: 1, nome: 'Equação do 1º grau'),
  Assunto(id: 3, idMateria: 1, nome: 'Equação do 2º grau'),
  Assunto(id: 4, idMateria: 1, nome: 'Funções'),
  Assunto(id: 5, idMateria: 1, nome: 'Logaritmo'),
  Assunto(id: 6, idMateria: 2, nome: 'Iluminismo'),
  Assunto(id: 7, idMateria: 2, nome: 'Revolução Industrial'),
];

/// Arestas `prerequisito → dependente` do conteúdo original.
const dependenciasExemplo = <Dependencia>[
  Dependencia(prerequisito: 2, dependente: 3, peso: 0.9),
  Dependencia(prerequisito: 2, dependente: 4, peso: 0.8),
  Dependencia(prerequisito: 3, dependente: 5, peso: 0.6),
  Dependencia(prerequisito: 4, dependente: 5, peso: 0.7),
  Dependencia(prerequisito: 1, dependente: 5, peso: 1.0),
  Dependencia(prerequisito: 6, dependente: 7, peso: 0.8),
];

const questoesExemplo = <Questao>[
  Questao(
    id: 1,
    idAssunto: 1,
    enunciado: 'Qual o valor de 2³ · 2²?',
    explicacao: 'Bases iguais: somam-se os expoentes. 2³ · 2² = 2⁵ = 32.',
    dificuldade: 1,
    alternativas: [
      Alternativa(letra: 'A', texto: '16', correta: false),
      Alternativa(letra: 'B', texto: '32', correta: true),
      Alternativa(letra: 'C', texto: '64', correta: false),
      Alternativa(letra: 'D', texto: '10', correta: false),
    ],
  ),
  Questao(
    id: 2,
    idAssunto: 2,
    enunciado: 'Qual a solução de 3x − 9 = 0?',
    explicacao: 'Isolando x: 3x = 9, logo x = 3.',
    dificuldade: 1,
    alternativas: [
      Alternativa(letra: 'A', texto: 'x = 9', correta: false),
      Alternativa(letra: 'B', texto: 'x = −3', correta: false),
      Alternativa(letra: 'C', texto: 'x = 3', correta: true),
      Alternativa(letra: 'D', texto: 'x = 0', correta: false),
    ],
  ),
  Questao(
    id: 3,
    idAssunto: 3,
    enunciado: 'Quais são as raízes de x² − 5x + 6 = 0?',
    explicacao: 'Soma 5 e produto 6: as raízes são 2 e 3.',
    dificuldade: 2,
    alternativas: [
      Alternativa(letra: 'A', texto: '1 e 6', correta: false),
      Alternativa(letra: 'B', texto: '2 e 3', correta: true),
      Alternativa(letra: 'C', texto: '−2 e −3', correta: false),
      Alternativa(letra: 'D', texto: '5 e 6', correta: false),
    ],
  ),
  Questao(
    id: 4,
    idAssunto: 4,
    enunciado: 'Se f(x) = 2x + 1, qual o valor de f(4)?',
    explicacao: 'Substituindo: f(4) = 2 · 4 + 1 = 9.',
    dificuldade: 1,
    alternativas: [
      Alternativa(letra: 'A', texto: '7', correta: false),
      Alternativa(letra: 'B', texto: '8', correta: false),
      Alternativa(letra: 'C', texto: '9', correta: true),
      Alternativa(letra: 'D', texto: '10', correta: false),
    ],
  ),
  Questao(
    id: 5,
    idAssunto: 5,
    enunciado: 'Qual o valor de log₂ 32?',
    explicacao: '32 = 2⁵, portanto log₂ 32 = 5.',
    dificuldade: 3,
    alternativas: [
      Alternativa(letra: 'A', texto: '4', correta: false),
      Alternativa(letra: 'B', texto: '5', correta: true),
      Alternativa(letra: 'C', texto: '6', correta: false),
      Alternativa(letra: 'D', texto: '16', correta: false),
    ],
  ),
  Questao(
    id: 6,
    idAssunto: 6,
    enunciado:
        'Qual pensador iluminista defendeu a separação dos três poderes?',
    explicacao: 'Montesquieu, em "O Espírito das Leis" (1748).',
    dificuldade: 2,
    alternativas: [
      Alternativa(letra: 'A', texto: 'Voltaire', correta: false),
      Alternativa(letra: 'B', texto: 'Rousseau', correta: false),
      Alternativa(letra: 'C', texto: 'Montesquieu', correta: true),
      Alternativa(letra: 'D', texto: 'John Locke', correta: false),
    ],
  ),
  Questao(
    id: 7,
    idAssunto: 7,
    enunciado: 'Em que país teve início a Revolução Industrial?',
    explicacao: 'Na Inglaterra, na segunda metade do século XVIII.',
    dificuldade: 1,
    alternativas: [
      Alternativa(letra: 'A', texto: 'França', correta: false),
      Alternativa(letra: 'B', texto: 'Inglaterra', correta: true),
      Alternativa(letra: 'C', texto: 'Alemanha', correta: false),
      Alternativa(letra: 'D', texto: 'Estados Unidos', correta: false),
    ],
  ),
  Questao(
    id: 8,
    idAssunto: 1,
    enunciado: 'Qual o valor de (3²)³?',
    explicacao: 'Potência de potência: multiplicam-se os expoentes. 3⁶ = 729.',
    dificuldade: 2,
    alternativas: [
      Alternativa(letra: 'A', texto: '27', correta: false),
      Alternativa(letra: 'B', texto: '81', correta: false),
      Alternativa(letra: 'C', texto: '729', correta: true),
      Alternativa(letra: 'D', texto: '243', correta: false),
    ],
  ),
  Questao(
    id: 9,
    idAssunto: 2,
    enunciado: 'Qual o valor de x em 5x + 2 = 3x + 10?',
    explicacao: 'Agrupando: 2x = 8, logo x = 4.',
    dificuldade: 2,
    alternativas: [
      Alternativa(letra: 'A', texto: 'x = 2', correta: false),
      Alternativa(letra: 'B', texto: 'x = 4', correta: true),
      Alternativa(letra: 'C', texto: 'x = 6', correta: false),
      Alternativa(letra: 'D', texto: 'x = 8', correta: false),
    ],
  ),
  Questao(
    id: 10,
    idAssunto: 4,
    enunciado: 'Qual é o coeficiente angular da reta y = −3x + 7?',
    explicacao: 'Na forma y = ax + b, o coeficiente angular é a, ou seja, −3.',
    dificuldade: 3,
    alternativas: [
      Alternativa(letra: 'A', texto: '7', correta: false),
      Alternativa(letra: 'B', texto: '3', correta: false),
      Alternativa(letra: 'C', texto: '−3', correta: true),
      Alternativa(letra: 'D', texto: '−7', correta: false),
    ],
  ),
];

// --- buscas simples nas listas acima ----------------------------------------

Materia? materiaPorId(int id) =>
    materiasExemplo.where((m) => m.id == id).firstOrNull;

Assunto? assuntoPorId(int id) =>
    assuntosExemplo.where((a) => a.id == id).firstOrNull;

Questao? questaoPorId(int id) =>
    questoesExemplo.where((q) => q.id == id).firstOrNull;

List<Assunto> assuntosDaMateria(int idMateria) =>
    assuntosExemplo.where((a) => a.idMateria == idMateria).toList();

/// Questões de uma matéria, ou todas quando [idMateria] é nulo.
List<Questao> questoesDaMateria(int? idMateria) {
  if (idMateria == null) return questoesExemplo;
  final ids = assuntosDaMateria(idMateria).map((a) => a.id).toSet();
  return questoesExemplo.where((q) => ids.contains(q.idAssunto)).toList();
}
