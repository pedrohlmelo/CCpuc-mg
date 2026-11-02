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

/// Conteúdo completo do app (índice + matérias), vindo dos assets ou do
/// Firestore. Os dois caminhos entregam os mesmos mapas a [PacoteConteudo.deMapas].
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

  /// [indice] é o `indice.json`; [arquivos] são os documentos das matérias.
  factory PacoteConteudo.deMapas(
    Map<String, dynamic> indice,
    List<Map<String, dynamic>> arquivos,
  ) {
    try {
      final assuntos = <Assunto>[];
      final dependencias = <Dependencia>[
        for (final d in _lista(indice['dependencias_entre_materias']))
          _dependencia(d),
      ];
      final questoes = <Questao>[];
      for (final arquivo in arquivos) {
        final idMateria = arquivo['materia'] as int;
        for (final a in _lista(arquivo['assuntos'])) {
          assuntos.add(
            Assunto(
              id: a['id'] as int,
              idMateria: idMateria,
              nome: a['nome'] as String,
              descricao: a['descricao'] as String? ?? '',
            ),
          );
        }
        dependencias.addAll(_lista(arquivo['dependencias']).map(_dependencia));
        questoes.addAll(_lista(arquivo['questoes']).map(_questao));
      }
      return PacoteConteudo(
        versao: indice['versao'] as int,
        materias: [
          for (final m in _lista(indice['materias']))
            Materia(
              id: m['id'] as int,
              nome: m['nome'] as String,
              area: m['area'] as String,
            ),
        ],
        assuntos: assuntos,
        dependencias: dependencias,
        questoes: questoes,
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

  static Questao _questao(Map<String, dynamic> q) => Questao(
    id: q['id'] as int,
    idAssunto: q['assunto'] as int,
    enunciado: q['enunciado'] as String,
    explicacao: q['explicacao'] as String,
    dificuldade: q['dificuldade'] as int,
    imagemUrl: q['imagem'] as String?,
    imagemDescricao: q['imagem_descricao'] as String?,
    fonte: q['fonte'] as String?,
    explicacaoGerada: q['explicacao_gerada'] as bool? ?? false,
    revisado: q['revisado'] as bool? ?? false,
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

  /// Lança [PacoteInvalido] no primeiro problema encontrado.
  void validar() {
    final idsMaterias = _unicos(materias.map((m) => m.id), 'matéria');
    final idsAssuntos = _unicos(assuntos.map((a) => a.id), 'assunto');
    _unicos(questoes.map((q) => q.id), 'questão');

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
    for (final q in questoes) {
      if (!idsAssuntos.contains(q.idAssunto)) {
        throw PacoteInvalido('questão ${q.id} sem assunto');
      }
      if (q.dificuldade < 1 || q.dificuldade > 3) {
        throw PacoteInvalido('questão ${q.id} com dificuldade inválida');
      }
      if (q.alternativas.where((a) => a.correta).length != 1) {
        throw PacoteInvalido('questão ${q.id} sem exatamente uma correta');
      }
      final letras = q.alternativas.map((a) => a.letra).toSet();
      if (letras.length != q.alternativas.length) {
        throw PacoteInvalido('questão ${q.id} com letra repetida');
      }
      if (q.alternativas.any((a) => a.texto == null && a.imagemUrl == null)) {
        throw PacoteInvalido('questão ${q.id} com alternativa vazia');
      }
    }
  }

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

/// Grava o pacote numa transação. As colunas que não vêm do pacote
/// (`dificuldade_calibrada`, `imagem_local`) e o progresso ficam como estão.
Future<void> aplicarConteudo(Database db, PacoteConteudo pacote) async {
  pacote.validar();
  await db.transaction((txn) async {
    final lote = txn.batch();
    for (final m in pacote.materias) {
      _upsert(lote, 'Materia', {'id': m.id, 'nome': m.nome, 'area': m.area});
    }
    for (final a in pacote.assuntos) {
      _upsert(lote, 'Assunto', {
        'id': a.id,
        'id_materia': a.idMateria,
        'nome': a.nome,
        'descricao': a.descricao,
      });
    }
    lote.delete('Grafo_Dependencia');
    for (final d in pacote.dependencias) {
      lote.insert('Grafo_Dependencia', {
        'id_prerequisito': d.prerequisito,
        'id_dependente': d.dependente,
        'peso': d.peso,
      });
    }
    for (final q in pacote.questoes) {
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
      });
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
