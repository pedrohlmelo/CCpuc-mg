import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../grafo/grafo_conhecimento.dart';
import '../banco/banco_local.dart';
import '../banco/pacote_conteudo.dart';
import '../estado_app.dart';
import '../modelos.dart';
import '../sincronizacao/servico_sincronizacao.dart';
import 'conteudo_repositorio.dart';
import 'grafo_repositorio.dart';

/// Primeiro id das questões criadas pelo painel: fica longe das do ENEM e das
/// autorais dos scripts.
const primeiroIdQuestaoAdmin = 9000001;
const ultimoIdQuestaoAdmin = 9999999;
const fonteAutoral = 'Autoral — Adapta';
const letrasAlternativas = ['A', 'B', 'C', 'D', 'E'];

/// Ação recusada. [campos] liga o erro ao campo do formulário, e [caminho] é o
/// ciclo que uma aresta fecharia.
class ErroAdmin implements Exception {
  final String mensagem;
  final Map<String, String> campos;
  final List<int>? caminho;
  const ErroAdmin(this.mensagem, {this.campos = const {}, this.caminho});

  @override
  String toString() => mensagem;
}

/// O que sai junto numa exclusão, para a confirmação.
class ImpactoExclusao {
  final int assuntos;
  final int questoes;
  const ImpactoExclusao({this.assuntos = 0, this.questoes = 0});
}

/// Escrita do painel administrativo (RF11). Grava só no SQLite, numa
/// transação, e marca a matéria ou a questão como pendente
/// (`sincronizado = 0`); o envio ao Firestore é do `ServicoSincronizacao`.
///
/// Nada é apagado de verdade: o histórico, a memória e a proficiência dos
/// alunos apontam para esses ids. Excluir é `ativo = 0`.
class AdminConteudoRepositorio {
  final BancoLocal _banco;
  final Usuario? Function() usuarioAtual;
  final void Function()? aoMudar;

  AdminConteudoRepositorio(
    this._banco, {
    required this.usuarioAtual,
    this.aoMudar,
  });

  static String agora() => DateTime.now().toUtc().toIso8601String();

  void _exigirAdmin() {
    if (!(usuarioAtual()?.isAdmin ?? false)) {
      throw const ErroAdmin('Só o administrador pode alterar o conteúdo.');
    }
  }

  Future<T> _gravar<T>(Future<T> Function(Transaction txn) acao) async {
    _exigirAdmin();
    final db = await _banco.db;
    final resultado = await db.transaction(acao);
    aoMudar?.call();
    return resultado;
  }

  static Future<void> _marcarMaterias(
    Transaction txn,
    Iterable<int> ids,
  ) async {
    for (final id in ids.toSet()) {
      await txn.update(
        'Materia',
        {'sincronizado': 0, 'atualizado_em': agora()},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  static Future<int?> _materiaDoAssunto(Transaction txn, int idAssunto) async {
    final l = await txn.query(
      'Assunto',
      columns: ['id_materia'],
      where: 'id = ?',
      whereArgs: [idAssunto],
    );
    return l.isEmpty ? null : l.first['id_materia'] as int;
  }

  static String _limpo(String texto) => texto.trim();

  // ---------------------------------------------------------------- matérias

  Future<int> criarMateria(String nome, String area) => _gravar((txn) async {
    nome = _limpo(nome);
    await _validarMateria(txn, nome, area);
    final maior = await txn.rawQuery('SELECT MAX(id) AS m FROM Materia');
    final id = ((maior.first['m'] as int?) ?? 0) + 1;
    await txn.insert('Materia', {
      'id': id,
      'nome': nome,
      'area': area,
      'ativo': 1,
      'sincronizado': 0,
      'atualizado_em': agora(),
    });
    return id;
  });

  Future<void> editarMateria(int id, String nome, String area) =>
      _gravar((txn) async {
        nome = _limpo(nome);
        await _validarMateria(txn, nome, area, ignorar: id);
        await txn.update(
          'Materia',
          {'nome': nome, 'area': area},
          where: 'id = ?',
          whereArgs: [id],
        );
        await _marcarMaterias(txn, [id]);
      });

  Future<void> _validarMateria(
    Transaction txn,
    String nome,
    String area, {
    int? ignorar,
  }) async {
    if (nome.isEmpty) {
      throw const ErroAdmin(
        'Informe o nome da matéria.',
        campos: {'nome': 'Obrigatório'},
      );
    }
    if (!areasValidas.contains(area)) {
      throw const ErroAdmin('Escolha a área.', campos: {'area': 'Obrigatório'});
    }
    final iguais = await txn.query(
      'Materia',
      where: 'LOWER(nome) = LOWER(?) AND id != ?',
      whereArgs: [nome, ignorar ?? -1],
    );
    if (iguais.isNotEmpty) {
      throw const ErroAdmin(
        'Já existe uma matéria com esse nome.',
        campos: {'nome': 'Já existe'},
      );
    }
  }

  Future<ImpactoExclusao> impactoMateria(int id) async {
    final db = await _banco.db;
    final assuntos = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Assunto WHERE id_materia = ? AND ativo = 1',
      [id],
    );
    final questoes = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Questao WHERE ativo = 1 AND id_assunto IN '
      '(SELECT id FROM Assunto WHERE id_materia = ?)',
      [id],
    );
    return ImpactoExclusao(
      assuntos: assuntos.first['n'] as int,
      questoes: questoes.first['n'] as int,
    );
  }

  /// Desativa a matéria, os assuntos e as questões dela, e tira as arestas
  /// que tocam esses assuntos.
  Future<void> excluirMateria(int id) => _gravar((txn) async {
    final assuntos = [
      for (final l in await txn.query(
        'Assunto',
        columns: ['id'],
        where: 'id_materia = ?',
        whereArgs: [id],
      ))
        l['id'] as int,
    ];
    await txn.update('Materia', {'ativo': 0}, where: 'id = ?', whereArgs: [id]);
    for (final a in assuntos) {
      await _desativarAssunto(txn, a);
    }
    await _marcarMaterias(txn, [id]);
  });

  /// Volta a matéria e os assuntos dela. As questões voltam uma a uma, pelo
  /// painel de questões, porque algumas já podiam estar inativas antes.
  Future<void> reativarMateria(int id) => _gravar((txn) async {
    await txn.update('Materia', {'ativo': 1}, where: 'id = ?', whereArgs: [id]);
    await txn.update(
      'Assunto',
      {'ativo': 1},
      where: 'id_materia = ?',
      whereArgs: [id],
    );
    await _marcarMaterias(txn, [id]);
  });

  // ---------------------------------------------------------------- assuntos

  Future<int> criarAssunto(int idMateria, String nome, String descricao) =>
      _gravar((txn) async {
        nome = _limpo(nome);
        await _validarAssunto(txn, idMateria, nome);
        final usados = {
          for (final l in await txn.query(
            'Assunto',
            columns: ['id'],
            where: 'id BETWEEN ? AND ?',
            whereArgs: [idMateria * 100 + 1, idMateria * 100 + 99],
          ))
            l['id'] as int,
        };
        int? id;
        for (var n = 1; n <= 99; n++) {
          if (!usados.contains(idMateria * 100 + n)) {
            id = idMateria * 100 + n;
            break;
          }
        }
        if (id == null) {
          throw const ErroAdmin('A matéria já tem 99 assuntos.');
        }
        await txn.insert('Assunto', {
          'id': id,
          'id_materia': idMateria,
          'nome': nome,
          'descricao': _limpo(descricao),
          'ativo': 1,
        });
        await _marcarMaterias(txn, [idMateria]);
        return id;
      });

  Future<void> editarAssunto(int id, String nome, String descricao) =>
      _gravar((txn) async {
        nome = _limpo(nome);
        final idMateria = await _materiaDoAssunto(txn, id);
        if (idMateria == null) throw const ErroAdmin('Assunto não encontrado.');
        await _validarAssunto(txn, idMateria, nome, ignorar: id);
        await txn.update(
          'Assunto',
          {'nome': nome, 'descricao': _limpo(descricao)},
          where: 'id = ?',
          whereArgs: [id],
        );
        await _marcarMaterias(txn, [idMateria]);
      });

  Future<void> _validarAssunto(
    Transaction txn,
    int idMateria,
    String nome, {
    int? ignorar,
  }) async {
    if (nome.isEmpty) {
      throw const ErroAdmin(
        'Informe o nome do assunto.',
        campos: {'nome': 'Obrigatório'},
      );
    }
    final materia = await txn.query(
      'Materia',
      where: 'id = ?',
      whereArgs: [idMateria],
    );
    if (materia.isEmpty) throw const ErroAdmin('Matéria não encontrada.');
    final iguais = await txn.query(
      'Assunto',
      where: 'id_materia = ? AND LOWER(nome) = LOWER(?) AND id != ?',
      whereArgs: [idMateria, nome, ignorar ?? -1],
    );
    if (iguais.isNotEmpty) {
      throw const ErroAdmin(
        'Já existe um assunto com esse nome nesta matéria.',
        campos: {'nome': 'Já existe'},
      );
    }
  }

  Future<ImpactoExclusao> impactoAssunto(int id) async {
    final db = await _banco.db;
    final questoes = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM Questao WHERE ativo = 1 AND id_assunto = ?',
      [id],
    );
    return ImpactoExclusao(questoes: questoes.first['n'] as int);
  }

  Future<void> excluirAssunto(int id) => _gravar((txn) async {
    final idMateria = await _materiaDoAssunto(txn, id);
    if (idMateria == null) throw const ErroAdmin('Assunto não encontrado.');
    await _desativarAssunto(txn, id);
    await _marcarMaterias(txn, [idMateria]);
  });

  Future<void> reativarAssunto(int id) => _gravar((txn) async {
    final idMateria = await _materiaDoAssunto(txn, id);
    if (idMateria == null) throw const ErroAdmin('Assunto não encontrado.');
    await txn.update('Assunto', {'ativo': 1}, where: 'id = ?', whereArgs: [id]);
    await _marcarMaterias(txn, [idMateria]);
  });

  /// Desativa o assunto e as questões dele e tira as arestas que o tocam,
  /// marcando as matérias do outro lado de cada aresta.
  static Future<void> _desativarAssunto(Transaction txn, int id) async {
    await txn.update('Assunto', {'ativo': 0}, where: 'id = ?', whereArgs: [id]);
    await txn.update(
      'Questao',
      {'ativo': 0, 'sincronizado': 0, 'atualizado_em': agora()},
      where: 'id_assunto = ? AND ativo = 1',
      whereArgs: [id],
    );
    final arestas = await txn.query(
      'Grafo_Dependencia',
      where: 'id_prerequisito = ? OR id_dependente = ?',
      whereArgs: [id, id],
    );
    final outros = <int>{};
    for (final a in arestas) {
      for (final v in [
        a['id_prerequisito'] as int,
        a['id_dependente'] as int,
      ]) {
        final m = await _materiaDoAssunto(txn, v);
        if (m != null) outros.add(m);
      }
    }
    await txn.delete(
      'Grafo_Dependencia',
      where: 'id_prerequisito = ? OR id_dependente = ?',
      whereArgs: [id, id],
    );
    await _marcarMaterias(txn, outros);
  }

  // ------------------------------------------------------------------ arestas

  /// Recusa a aresta que fecharia ciclo no grafo inteiro, com o caminho em
  /// [ErroAdmin.caminho], e a que já existe.
  Future<void> criarAresta(Dependencia aresta) => _gravar((txn) async {
    final pre = aresta.prerequisito;
    final dep = aresta.dependente;
    _validarPeso(aresta.peso);
    if (pre == dep) {
      throw const ErroAdmin('Um assunto não pode depender de si mesmo.');
    }
    final grafo = await _grafoInteiro(txn);
    if (grafo.criariaCiclo(pre, dep)) {
      throw ErroAdmin(
        'Essa aresta fecharia um ciclo.',
        caminho: [...grafo.caminho(dep, pre)!, dep],
      );
    }
    if (grafo.peso(pre, dep) != null) {
      throw const ErroAdmin('Essa dependência já existe.');
    }
    final mPre = await _materiaDoAssunto(txn, pre);
    final mDep = await _materiaDoAssunto(txn, dep);
    if (mPre == null || mDep == null) {
      throw const ErroAdmin('Assunto não encontrado.');
    }
    await txn.insert('Grafo_Dependencia', {
      'id_prerequisito': pre,
      'id_dependente': dep,
      'peso': aresta.peso,
    });
    await _marcarMaterias(txn, [mPre, mDep]);
  });

  Future<void> editarPeso(int pre, int dep, double peso) =>
      _gravar((txn) async {
        _validarPeso(peso);
        await txn.update(
          'Grafo_Dependencia',
          {'peso': peso},
          where: 'id_prerequisito = ? AND id_dependente = ?',
          whereArgs: [pre, dep],
        );
        await _marcarMateriasDaAresta(txn, pre, dep);
      });

  Future<void> removerAresta(int pre, int dep) => _gravar((txn) async {
    await txn.delete(
      'Grafo_Dependencia',
      where: 'id_prerequisito = ? AND id_dependente = ?',
      whereArgs: [pre, dep],
    );
    await _marcarMateriasDaAresta(txn, pre, dep);
  });

  static Future<void> _marcarMateriasDaAresta(
    Transaction txn,
    int pre,
    int dep,
  ) async => _marcarMaterias(
    txn,
    [
      await _materiaDoAssunto(txn, pre),
      await _materiaDoAssunto(txn, dep),
    ].nonNulls,
  );

  static void _validarPeso(double peso) {
    if (peso < 0.1 - 1e-9 || peso > 1.0 + 1e-9) {
      throw const ErroAdmin('O peso vai de 0,1 a 1,0.');
    }
  }

  static Future<GrafoConhecimento> _grafoInteiro(Transaction txn) async {
    final assuntos = await txn.query('Assunto', columns: ['id']);
    final arestas = await txn.query('Grafo_Dependencia');
    return GrafoConhecimento(
      [for (final a in assuntos) a['id'] as int],
      [
        for (final a in arestas)
          Dependencia(
            prerequisito: a['id_prerequisito'] as int,
            dependente: a['id_dependente'] as int,
            peso: (a['peso'] as num).toDouble(),
          ),
      ],
    );
  }

  // ----------------------------------------------------------------- questões

  /// Cria quando `questao.id == 0`; senão edita, preservando a
  /// `dificuldade_calibrada`. Devolve o id.
  Future<int> salvarQuestao(Questao questao) => _gravar((txn) async {
    await _validarQuestao(txn, questao);
    var id = questao.id;
    final linha = <String, Object?>{
      'id_assunto': questao.idAssunto,
      'enunciado': questao.enunciado.trim(),
      'explicacao': questao.explicacao.trim(),
      'dificuldade': questao.dificuldade,
      'imagem_url': _vazioNulo(questao.imagemUrl),
      'imagem_descricao': _vazioNulo(questao.imagemDescricao),
      'fonte': _vazioNulo(questao.fonte) ?? fonteAutoral,
      'revisado': questao.revisado ? 1 : 0,
      'ativo': questao.ativo ? 1 : 0,
      'sincronizado': 0,
      'atualizado_em': agora(),
    };
    if (id == 0) {
      final maior = await txn.rawQuery(
        'SELECT MAX(id) AS m FROM Questao WHERE id BETWEEN ? AND ?',
        [primeiroIdQuestaoAdmin, ultimoIdQuestaoAdmin],
      );
      id = ((maior.first['m'] as int?) ?? primeiroIdQuestaoAdmin - 1) + 1;
      if (id > ultimoIdQuestaoAdmin) {
        throw const ErroAdmin('Acabaram os ids de questões do painel.');
      }
      await txn.insert('Questao', {'id': id, ...linha, 'explicacao_gerada': 0});
    } else {
      final atual = await txn.query(
        'Questao',
        columns: ['explicacao'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (atual.isEmpty) throw const ErroAdmin('Questão não encontrada.');
      await txn.update(
        'Questao',
        {
          ...linha,
          if (atual.first['explicacao'] != linha['explicacao'])
            'explicacao_gerada': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await txn.delete(
      'Alternativa',
      where:
          'id_questao = ? AND letra NOT IN '
          '(${List.filled(letrasAlternativas.length, '?').join(', ')})',
      whereArgs: [id, ...letrasAlternativas],
    );
    for (final a in questao.alternativas) {
      final dados = {
        'id_questao': id,
        'letra': a.letra,
        'texto': _vazioNulo(a.texto),
        'correta': a.correta ? 1 : 0,
        'imagem_url': _vazioNulo(a.imagemUrl),
        'imagem_descricao': _vazioNulo(a.imagemDescricao),
      };
      final n = await txn.update(
        'Alternativa',
        dados,
        where: 'id_questao = ? AND letra = ?',
        whereArgs: [id, a.letra],
      );
      if (n == 0) await txn.insert('Alternativa', dados);
    }
    return id;
  });

  Future<void> definirQuestaoAtiva(int id, bool ativo) => _gravar((txn) async {
    if (ativo) {
      final l = await txn.rawQuery(
        'SELECT a.ativo AS assunto, m.ativo AS materia FROM Questao q '
        'JOIN Assunto a ON a.id = q.id_assunto '
        'JOIN Materia m ON m.id = a.id_materia WHERE q.id = ?',
        [id],
      );
      if (l.isEmpty || l.first['assunto'] != 1 || l.first['materia'] != 1) {
        throw const ErroAdmin(
          'Reative antes a matéria e o assunto desta questão.',
        );
      }
    }
    await txn.update(
      'Questao',
      {'ativo': ativo ? 1 : 0, 'sincronizado': 0, 'atualizado_em': agora()},
      where: 'id = ?',
      whereArgs: [id],
    );
  });

  static String? _vazioNulo(String? texto) {
    final t = texto?.trim();
    return t == null || t.isEmpty ? null : t;
  }

  /// As mesmas regras de `aplicarConteudo`, com o erro ligado ao campo.
  static Future<void> _validarQuestao(Transaction txn, Questao q) async {
    final erros = <String, String>{};
    final l = await txn.rawQuery(
      'SELECT a.ativo AS assunto, m.ativo AS materia FROM Assunto a '
      'JOIN Materia m ON m.id = a.id_materia WHERE a.id = ?',
      [q.idAssunto],
    );
    if (l.isEmpty) {
      erros['assunto'] = 'Escolha o assunto';
    } else if (l.first['assunto'] != 1 || l.first['materia'] != 1) {
      erros['assunto'] = 'Matéria ou assunto inativo';
    }
    if (q.enunciado.trim().isEmpty) erros['enunciado'] = 'Obrigatório';
    if (q.explicacao.trim().isEmpty) erros['explicacao'] = 'Obrigatória';
    if (q.dificuldade < 1 || q.dificuldade > 3) {
      erros['dificuldade'] = 'De 1 a 3';
    }
    final letras = q.alternativas.map((a) => a.letra).toList();
    if (letras.length != 5 || !letrasAlternativas.every(letras.contains)) {
      erros['alternativas'] = 'São 5 alternativas, de A a E';
    }
    for (final a in q.alternativas) {
      if (_vazioNulo(a.texto) == null && _vazioNulo(a.imagemUrl) == null) {
        erros['alternativa_${a.letra}'] = 'Texto ou imagem';
      }
    }
    if (q.alternativas.where((a) => a.correta).length != 1) {
      erros['alternativas'] = 'Marque exatamente uma correta';
    }
    if (erros.isNotEmpty) {
      throw ErroAdmin('Confira os campos destacados.', campos: erros);
    }
  }

  // ---------------------------------------------------------------- pendentes

  /// Matérias e questões mudadas no aparelho que ainda não subiram.
  Future<int> contarPendentes() async {
    final db = await _banco.db;
    final l = await db.rawQuery(
      'SELECT (SELECT COUNT(*) FROM Materia WHERE sincronizado = 0) '
      '+ (SELECT COUNT(*) FROM Questao WHERE sincronizado = 0) AS n',
    );
    return l.first['n'] as int;
  }
}

final adminConteudoRepositorioProvider = Provider<AdminConteudoRepositorio>(
  (ref) => AdminConteudoRepositorio(
    ref.watch(bancoProvider),
    usuarioAtual: () => ref.read(usuarioProvider),
    aoMudar: () {
      ref.invalidate(conteudoProvider);
      ref.invalidate(dependenciasProvider);
      ref.invalidate(grafoProvider);
      // A gravação local já terminou; a tela não espera a nuvem.
      unawaited(enviarConteudoAdmin(ref));
    },
  ),
);

/// Para o painel inicial do admin. Relido sempre que o conteúdo muda, o que
/// acontece depois de cada gravação e de cada envio.
final pendentesAdminProvider = FutureProvider<int>((ref) async {
  ref.watch(conteudoProvider);
  return AdminConteudoRepositorio(
    ref.watch(bancoProvider),
    usuarioAtual: () => null,
  ).contarPendentes();
});
