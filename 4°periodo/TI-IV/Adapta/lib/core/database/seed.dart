import 'package:sqflite/sqflite.dart';

import '../seguranca/hash_senha.dart';

/// Dados iniciais para desenvolvimento e testes.
///
/// Uma matéria com um grafo pequeno (5 vértices) e uma questão por assunto.
/// A matéria definitiva do MVP e a curadoria real do grafo continuam em aberto
/// (ver `docs/MODELAGEM.md`, seção 8).
Future<void> inserirSeed(DatabaseExecutor db) async {
  await db.insert('Usuario', {
    'nome': 'Administrador',
    'email': 'admin@adapta.app',
    'senha': HashSenha.gerar('admin123'),
    'tipo': 'admin',
  });

  final matematica = await db.insert('Materia', {'nome': 'Matemática'});
  final historia = await db.insert('Materia', {'nome': 'História'});

  Future<int> assunto(int materia, String nome) =>
      db.insert('Assunto', {'id_materia': materia, 'nome': nome});

  final potenciacao = await assunto(matematica, 'Potenciação');
  final eq1 = await assunto(matematica, 'Equação do 1º grau');
  final eq2 = await assunto(matematica, 'Equação do 2º grau');
  final funcoes = await assunto(matematica, 'Funções');
  final logaritmo = await assunto(matematica, 'Logaritmo');
  final iluminismo = await assunto(historia, 'Iluminismo');
  final revIndustrial = await assunto(historia, 'Revolução Industrial');

  Future<void> aresta(int pre, int dep, double peso) => db.insert(
    'Grafo_Dependencia',
    {'id_prerequisito': pre, 'id_dependente': dep, 'peso': peso},
  );

  await aresta(eq1, eq2, 0.9);
  await aresta(eq1, funcoes, 0.8);
  await aresta(eq2, logaritmo, 0.6);
  await aresta(funcoes, logaritmo, 0.7);
  await aresta(potenciacao, logaritmo, 1.0);
  await aresta(iluminismo, revIndustrial, 0.8);

  Future<void> questao(
    int assunto,
    String enunciado,
    String explicacao,
    int dificuldade,
    List<String> alternativas,
    String correta,
  ) async {
    final id = await db.insert('Questao', {
      'id_assunto': assunto,
      'enunciado': enunciado,
      'explicacao': explicacao,
      'dificuldade': dificuldade,
    });
    for (var i = 0; i < alternativas.length; i++) {
      final letra = String.fromCharCode('A'.codeUnitAt(0) + i);
      await db.insert('Alternativa', {
        'id_questao': id,
        'letra': letra,
        'texto': alternativas[i],
        'correta': letra == correta ? 1 : 0,
      });
    }
  }

  await questao(
    potenciacao,
    'Qual o valor de 2³ · 2²?',
    'Bases iguais: somam-se os expoentes. 2³ · 2² = 2⁵ = 32.',
    1,
    ['16', '32', '64', '10'],
    'B',
  );
  await questao(
    eq1,
    'Qual a solução de 3x − 9 = 0?',
    'Isolando x: 3x = 9, logo x = 3.',
    1,
    ['x = 9', 'x = −3', 'x = 3', 'x = 0'],
    'C',
  );
  await questao(
    eq2,
    'Quais são as raízes de x² − 5x + 6 = 0?',
    'Soma 5 e produto 6: raízes 2 e 3.',
    2,
    ['1 e 6', '2 e 3', '−2 e −3', '5 e 6'],
    'B',
  );
  await questao(
    funcoes,
    'Se f(x) = 2x + 1, qual o valor de f(4)?',
    'Substituindo: f(4) = 2·4 + 1 = 9.',
    1,
    ['7', '8', '9', '10'],
    'C',
  );
  await questao(
    logaritmo,
    'Qual o valor de log₂ 32?',
    '32 = 2⁵, portanto log₂ 32 = 5.',
    3,
    ['4', '5', '6', '16'],
    'B',
  );
  await questao(
    iluminismo,
    'Qual pensador iluminista defendeu a separação dos três poderes?',
    'Montesquieu, em "O Espírito das Leis" (1748).',
    2,
    ['Voltaire', 'Rousseau', 'Montesquieu', 'Locke'],
    'C',
  );
  await questao(
    revIndustrial,
    'Em que país teve início a Revolução Industrial?',
    'Inglaterra, na segunda metade do século XVIII.',
    1,
    ['França', 'Inglaterra', 'Alemanha', 'Estados Unidos'],
    'B',
  );
}
