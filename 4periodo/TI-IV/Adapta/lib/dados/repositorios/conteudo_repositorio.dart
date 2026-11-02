import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../banco/banco_local.dart';
import '../modelos.dart';

/// Conteúdo já lido do banco, com buscas síncronas para as telas.
class Conteudo {
  final List<Materia> materias;
  final List<Assunto> assuntos;

  /// Só as ativas. As inativas ficam em [questaoPorId], para o histórico.
  final List<Questao> questoes;
  final List<Questao> inativas;

  Conteudo({
    required this.materias,
    required this.assuntos,
    required this.questoes,
    this.inativas = const [],
  });

  late final _questoesPorId = {
    for (final q in [...questoes, ...inativas]) q.id: q,
  };

  Materia? materiaPorId(int id) =>
      materias.where((m) => m.id == id).firstOrNull;

  Assunto? assuntoPorId(int id) =>
      assuntos.where((a) => a.id == id).firstOrNull;

  Questao? questaoPorId(int id) => _questoesPorId[id];

  String nomeDoAssunto(int id) => assuntoPorId(id)?.nome ?? 'Assunto #$id';

  List<Assunto> assuntosDaMateria(int idMateria) =>
      assuntos.where((a) => a.idMateria == idMateria).toList();

  /// Questões de uma matéria, ou todas quando [idMateria] é nulo.
  List<Questao> questoesDaMateria(int? idMateria) {
    if (idMateria == null) return questoes;
    final ids = assuntosDaMateria(idMateria).map((a) => a.id).toSet();
    return questoes.where((q) => ids.contains(q.idAssunto)).toList();
  }

  /// Matéria a que a questão pertence, via assunto.
  Materia? materiaDaQuestao(Questao questao) {
    final assunto = assuntoPorId(questao.idAssunto);
    return assunto == null ? null : materiaPorId(assunto.idMateria);
  }
}

class ConteudoRepositorio {
  final BancoLocal _banco;
  ConteudoRepositorio(this._banco);

  Future<Conteudo> carregar() async {
    final db = await _banco.db;
    final materias = await db.query('Materia', orderBy: 'id');
    final assuntos = await db.query('Assunto', orderBy: 'id');
    final questoes = await db.query('Questao', orderBy: 'id');
    final alternativas = await db.query('Alternativa', orderBy: 'letra');

    final porQuestao = <int, List<Alternativa>>{};
    for (final a in alternativas) {
      (porQuestao[a['id_questao'] as int] ??= []).add(
        Alternativa(
          letra: a['letra'] as String,
          texto: a['texto'] as String?,
          correta: a['correta'] == 1,
          imagemUrl: a['imagem_url'] as String?,
          imagemLocal: a['imagem_local'] as String?,
          imagemDescricao: a['imagem_descricao'] as String?,
        ),
      );
    }

    final todas = [
      for (final q in questoes)
        Questao(
          id: q['id'] as int,
          idAssunto: q['id_assunto'] as int,
          enunciado: q['enunciado'] as String,
          explicacao: q['explicacao'] as String,
          dificuldade: q['dificuldade'] as int,
          dificuldadeCalibrada: q['dificuldade_calibrada'] as double?,
          imagemUrl: q['imagem_url'] as String?,
          imagemLocal: q['imagem_local'] as String?,
          imagemDescricao: q['imagem_descricao'] as String?,
          fonte: q['fonte'] as String?,
          explicacaoGerada: q['explicacao_gerada'] == 1,
          revisado: q['revisado'] == 1,
          ativo: q['ativo'] == 1,
          alternativas: porQuestao[q['id'] as int] ?? const [],
        ),
    ];

    return Conteudo(
      materias: [
        for (final m in materias)
          Materia(
            id: m['id'] as int,
            nome: m['nome'] as String,
            area: m['area'] as String,
          ),
      ],
      assuntos: [
        for (final a in assuntos)
          Assunto(
            id: a['id'] as int,
            idMateria: a['id_materia'] as int,
            nome: a['nome'] as String,
            descricao: a['descricao'] as String,
          ),
      ],
      questoes: todas.where((q) => q.ativo).toList(),
      inativas: todas.where((q) => !q.ativo).toList(),
    );
  }

  /// Dificuldade `b` de uma questão, depois de recalibrada pelo modelo.
  Future<void> gravarDificuldadeCalibrada(int idQuestao, double valor) async {
    final db = await _banco.db;
    await db.update(
      'Questao',
      {'dificuldade_calibrada': valor},
      where: 'id = ?',
      whereArgs: [idQuestao],
    );
  }

  /// Preenche, só onde ainda está vazia, a dificuldade treinada de cada questão.
  Future<void> preencherDificuldades(Map<int, double> dificuldades) async {
    final db = await _banco.db;
    final lote = db.batch();
    dificuldades.forEach((id, valor) {
      lote.update(
        'Questao',
        {'dificuldade_calibrada': valor},
        where: 'id = ? AND dificuldade_calibrada IS NULL',
        whereArgs: [id],
      );
    });
    await lote.commit(noResult: true);
  }
}

final conteudoRepositorioProvider = Provider<ConteudoRepositorio>(
  (ref) => ConteudoRepositorio(ref.watch(bancoProvider)),
);

final conteudoProvider = FutureProvider<Conteudo>(
  (ref) => ref.watch(conteudoRepositorioProvider).carregar(),
);
