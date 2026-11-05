import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../grafo/grafo_conhecimento.dart';
import '../modelos.dart';

const areasValidas = {'linguagens', 'humanas', 'natureza', 'matematica'};

/// O pacote recebido não respeita as regras do conteúdo e não é aplicado.
class PacoteInvalido implements Exception {
  final String motivo;
  const PacoteInvalido(this.motivo);

  @override
  String toString() => 'PacoteInvalido: $motivo';
}

/// Conteúdo do app, vindo do pacote inicial ou do Firestore. Os dois caminhos
/// entregam documentos iguais a [PacoteConteudo.deDocumentos], e uma página de
/// questões do Firestore é um pacote só com questões.
class PacoteConteudo {
  final int versao;
  final List<Materia> materias;
  final List<Assunto> assuntos;
  final List<Dependencia> dependencias;
  final List<Questao> questoes;

  const PacoteConteudo({
    required this.versao,
    required this.materias,
    required this.assuntos,
    required this.dependencias,
    required this.questoes,
  });

  /// [meta] é `meta/conteudo`, [materias] são os documentos de `materias/*` e
  /// [questoes] os de `questoes/*`. Questão malformada é descartada e logada.
  factory PacoteConteudo.deDocumentos(
    Map<String, dynamic> meta,
    List<Map<String, dynamic>> materias,
    List<Map<String, dynamic>> questoes,
  ) {
    try {
      return PacoteConteudo(
        versao: meta['versao'] as int,
        materias: [
          for (final m in materias)
            Materia(
              id: m['id'] as int,
              nome: m['nome'] as String,
              area: m['area'] as String,
              ativo: m['ativo'] as bool? ?? true,
            ),
        ],
        assuntos: [
          for (final m in materias)
            for (final a in _lista(m['assuntos']))
              Assunto(
                id: a['id'] as int,
                idMateria: m['id'] as int,
                nome: a['nome'] as String,
                descricao: a['descricao'] as String? ?? '',
                ativo: a['ativo'] as bool? ?? true,
              ),
        ],
        dependencias: [
          for (final d in _lista(meta['dependencias_entre_materias']))
            _dependencia(d),
          for (final m in materias)
            for (final d in _lista(m['dependencias'])) _dependencia(d),
        ],
        questoes: questoes.map(_questaoOuNulo).nonNulls.toList(),
      );
    } on TypeError catch (erro) {
      throw PacoteInvalido('campo ausente ou de tipo errado: $erro');
    }
  }

  static Iterable<Map<String, dynamic>> _lista(Object? valor) =>
      (valor as List? ?? const []).cast<Map<String, dynamic>>();

  static Dependencia _dependencia(Map<String, dynamic> d) => Dependencia(
    prerequisito: d['pre'] as int,
    dependente: d['dep'] as int,
    peso: (d['peso'] as num).toDouble(),
  );

  static Questao? _questaoOuNulo(Map<String, dynamic> q) {
    try {
      return _questao(q);
    } on TypeError catch (erro) {
      _descartar(q['id'], 'campo ausente ou de tipo errado: $erro');
      return null;
    }
  }

  static Questao _questao(Map<String, dynamic> q) => Questao(
    id: q['id'] as int,
    idAssunto: q['assunto'] as int,
    enunciado: q['enunciado'] as String,
    explicacao: q['explicacao'] as String,
    dificuldade: q['dificuldade'] as int,
    dificuldadeIrt: (q['dificuldade_irt'] as num?)?.toDouble(),
    imagemUrl: q['imagem'] as String?,
    imagemDescricao: q['imagem_descricao'] as String?,
    fonte: q['fonte'] as String?,
    explicacaoGerada: q['explicacao_gerada'] as bool? ?? false,
    revisado: q['revisado'] as bool? ?? false,
    ativo: q['ativo'] as bool? ?? true,
    alternativas: [
      for (final a in _lista(q['alternativas']))
        Alternativa(
          letra: a['letra'] as String,
          texto: a['texto'] as String?,
          correta: a['correta'] as bool,
          imagemUrl: a['imagem'] as String?,
          imagemDescricao: a['imagem_descricao'] as String?,
        ),
    ],
  );

  /// Valida o que sustenta o app: matérias, assuntos e o grafo. Lança
  /// [PacoteInvalido] no primeiro problema, e nada do pacote é aplicado.
  void validar() {
    final idsMaterias = _unicos(materias.map((m) => m.id), 'matéria');
    final idsAssuntos = _unicos(assuntos.map((a) => a.id), 'assunto');

    for (final m in materias) {
      if (!areasValidas.contains(m.area)) {
        throw PacoteInvalido('matéria ${m.id} com área "${m.area}"');
      }
    }
    for (final a in assuntos) {
      if (!idsMaterias.contains(a.idMateria)) {
        throw PacoteInvalido('assunto ${a.id} sem matéria');
      }
    }
    for (final d in dependencias) {
      if (!idsAssuntos.contains(d.prerequisito) ||
          !idsAssuntos.contains(d.dependente)) {
        throw PacoteInvalido(
          'aresta ${d.prerequisito} → ${d.dependente} sem assunto',
        );
      }
    }
    if (GrafoConhecimento(idsAssuntos.toList(), dependencias).temCiclo) {
      throw const PacoteInvalido('o grafo tem ciclo');
    }
  }

  /// Questões que podem ser gravadas; as outras são descartadas e logadas, sem
  /// derrubar o resto. [idsAssuntos] inclui os assuntos que já estão no banco.
  List<Questao> questoesValidas(Set<int> idsAssuntos) {
    final vistas = <int>{};
    final validas = <Questao>[];
    for (final q in questoes) {
      final problema = !vistas.add(q.id)
          ? 'repetida'
          : _problemaDaQuestao(q, idsAssuntos);
      if (problema == null) {
        validas.add(q);
      } else {
        _descartar(q.id, problema);
      }
    }
    return validas;
  }

  static String? _problemaDaQuestao(Questao q, Set<int> idsAssuntos) {
    if (!idsAssuntos.contains(q.idAssunto)) return 'sem assunto';
    if (q.dificuldade < 1 || q.dificuldade > 3) return 'dificuldade inválida';
    if (q.alternativas.where((a) => a.correta).length != 1) {
      return 'sem exatamente uma correta';
    }
    final letras = q.alternativas.map((a) => a.letra).toSet();
    if (letras.length != q.alternativas.length) return 'letra repetida';
    if (q.alternativas.any((a) => a.texto == null && a.imagemUrl == null)) {
      return 'alternativa vazia';
    }
    return null;
  }

  static void _descartar(Object? id, String motivo) =>
      debugPrint('Questão $id descartada: $motivo');

  static Set<int> _unicos(Iterable<int> ids, String nome) {
    final vistos = <int>{};
    for (final id in ids) {
      if (!vistos.add(id)) throw PacoteInvalido('$nome $id repetido');
    }
    return vistos;
  }
}

/// `update` seguido de `insert or ignore`, e não `ON CONFLICT DO UPDATE`: o
/// sqflite usa o SQLite do sistema, e o Android abaixo da API 30 não tem upsert.
void _upsert(Batch lote, String tabela, Map<String, Object?> linha) {
  lote.update(tabela, linha, where: 'id = ?', whereArgs: [linha['id']]);
  lote.insert(tabela, linha, conflictAlgorithm: ConflictAlgorithm.ignore);
}

/// Grava o pacote numa transação. O progresso e a `imagem_local` ficam como
/// estão, e a `dificuldade_calibrada` só é preenchida se ainda estiver vazia.
/// O grafo só é reescrito quando o pacote traz arestas.
///
/// O que o admin mudou no aparelho e ainda não subiu (`sincronizado = 0`)
/// vence: a matéria pendente, os assuntos e as arestas dela e a questão
/// pendente ficam como estão.
Future<void> aplicarConteudo(Database db, PacoteConteudo pacote) async {
  pacote.validar();
  await db.transaction((txn) async {
    final materiasPendentes = {
      for (final l in await txn.query(
        'Materia',
        columns: ['id'],
        where: 'sincronizado = 0',
      ))
        l['id'] as int,
    };
    final assuntosPendentes = materiasPendentes.isEmpty
        ? const <int>{}
        : {
            for (final l in await txn.query(
              'Assunto',
              columns: ['id'],
              where:
                  'id_materia IN (${materiasPendentes.map((_) => '?').join(', ')})',
              whereArgs: materiasPendentes.toList(),
            ))
              l['id'] as int,
          };
    final questoesPendentes = {
      for (final l in await txn.query(
        'Questao',
        columns: ['id'],
        where: 'sincronizado = 0',
      ))
        l['id'] as int,
    };
    final assuntosNoBanco = await txn.query('Assunto', columns: ['id']);
    final questoes = pacote.questoesValidas({
      ...pacote.assuntos.map((a) => a.id),
      ...assuntosNoBanco.map((a) => a['id'] as int),
    });
    final lote = txn.batch();
    for (final m in pacote.materias) {
      if (materiasPendentes.contains(m.id)) continue;
      _upsert(lote, 'Materia', {
        'id': m.id,
        'nome': m.nome,
        'area': m.area,
        'ativo': m.ativo ? 1 : 0,
      });
    }
    for (final a in pacote.assuntos) {
      if (materiasPendentes.contains(a.idMateria) ||
          assuntosPendentes.contains(a.id)) {
        continue;
      }
      _upsert(lote, 'Assunto', {
        'id': a.id,
        'id_materia': a.idMateria,
        'nome': a.nome,
        'descricao': a.descricao,
        'ativo': a.ativo ? 1 : 0,
      });
    }
    bool tocaPendente(int pre, int dep) =>
        assuntosPendentes.contains(pre) || assuntosPendentes.contains(dep);
    if (pacote.dependencias.isNotEmpty) {
      if (assuntosPendentes.isEmpty) {
        lote.delete('Grafo_Dependencia');
      } else {
        final marcas = assuntosPendentes.map((_) => '?').join(', ');
        lote.delete(
          'Grafo_Dependencia',
          where:
              'id_prerequisito NOT IN ($marcas) AND id_dependente NOT IN ($marcas)',
          whereArgs: [...assuntosPendentes, ...assuntosPendentes],
        );
      }
    }
    for (final d in pacote.dependencias) {
      if (tocaPendente(d.prerequisito, d.dependente)) continue;
      lote.insert('Grafo_Dependencia', {
        'id_prerequisito': d.prerequisito,
        'id_dependente': d.dependente,
        'peso': d.peso,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    for (final q in questoes) {
      if (questoesPendentes.contains(q.id)) continue;
      _upsert(lote, 'Questao', {
        'id': q.id,
        'id_assunto': q.idAssunto,
        'enunciado': q.enunciado,
        'explicacao': q.explicacao,
        'dificuldade': q.dificuldade,
        'imagem_url': q.imagemUrl,
        'imagem_descricao': q.imagemDescricao,
        'fonte': q.fonte,
        'explicacao_gerada': q.explicacaoGerada ? 1 : 0,
        'revisado': q.revisado ? 1 : 0,
        'ativo': q.ativo ? 1 : 0,
      });
      if (q.dificuldadeIrt != null) {
        lote.update(
          'Questao',
          {'dificuldade_calibrada': q.dificuldadeIrt},
          where: 'id = ? AND dificuldade_calibrada IS NULL',
          whereArgs: [q.id],
        );
      }
      _trocarAlternativas(lote, q);
    }
    await lote.commit(noResult: true);
  });
}

/// A alternativa é atualizada pela letra, para manter o id de quem já existe.
void _trocarAlternativas(Batch lote, Questao q) {
  final letras = q.alternativas.map((a) => a.letra).toList();
  lote.delete(
    'Alternativa',
    where:
        'id_questao = ? AND letra NOT IN '
        '(${List.filled(letras.length, '?').join(', ')})',
    whereArgs: [q.id, ...letras],
  );
  for (final a in q.alternativas) {
    final linha = {
      'id_questao': q.id,
      'letra': a.letra,
      'texto': a.texto,
      'correta': a.correta ? 1 : 0,
      'imagem_url': a.imagemUrl,
      'imagem_descricao': a.imagemDescricao,
    };
    lote.update(
      'Alternativa',
      linha,
      where: 'id_questao = ? AND letra = ?',
      whereArgs: [q.id, a.letra],
    );
    lote.insert(
      'Alternativa',
      linha,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
}
