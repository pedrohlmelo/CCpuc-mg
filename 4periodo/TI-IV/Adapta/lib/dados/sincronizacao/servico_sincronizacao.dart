import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../banco/banco_local.dart';
import '../banco/pacote_conteudo.dart';
import '../estado_app.dart';
import '../firebase.dart';
import '../modelos.dart';
import '../preferencias.dart';
import '../repositorios/conteudo_repositorio.dart';
import '../repositorios/grafo_repositorio.dart';

/// Tamanho de cada lote: o Firestore aceita até 500 escritas por `WriteBatch`.
const _tamanhoLote = 400;

/// Questões por página no download do conteúdo.
const tamanhoPaginaConteudo = 300;

/// Sem rede, o `commit` fica esperando para sempre; a linha continua pendente
/// e sobe na próxima tentativa.
const _esperaEnvio = Duration(seconds: 20);

/// O aparelho avisa que a rede voltou antes de o Firestore reconectar: a
/// primeira tentativa pode falhar mesmo com internet.
const _esperasAoVoltar = [
  Duration(seconds: 5),
  Duration(seconds: 15),
  Duration(seconds: 30),
];

/// Chama [tentar] até dar certo, aguardando cada uma das [esperas].
Future<void> repetirAteConseguir(
  Future<bool> Function() tentar, {
  List<Duration> esperas = _esperasAoVoltar,
}) async {
  if (await tentar()) return;
  for (final espera in esperas) {
    await Future<void>.delayed(espera);
    if (await tentar()) return;
  }
}

enum ResultadoConteudo { atualizado, igual, falhou }

/// Rede do aparelho. Separada do serviço para os testes simularem o modo avião.
abstract class Conectividade {
  Future<bool> online();

  /// Emite a cada mudança de rede.
  Stream<bool> get mudancas;
}

class ConectividadePlus implements Conectividade {
  bool _conectado(List<ConnectivityResult> redes) =>
      redes.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> online() async {
    try {
      return _conectado(await Connectivity().checkConnectivity());
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<bool> get mudancas =>
      Connectivity().onConnectivityChanged.map(_conectado);
}

/// Copia o progresso do SQLite para `usuarios/{uid}/...` e traz o conteúdo do
/// Firestore para o SQLite, que continua sendo a fonte de verdade: nenhuma
/// falha aqui atrapalha o estudo.
class ServicoSincronizacao {
  final BancoLocal _banco;
  final FirebaseFirestore? _firestore;
  final Preferencias _preferencias;
  final Conectividade _conectividade;

  ServicoSincronizacao(
    this._banco,
    this._firestore,
    this._preferencias,
    this._conectividade,
  );

  bool _rodando = false;
  bool _repetir = false;
  Future<ResultadoConteudo>? _baixando;

  /// Traz matérias e questões quando a versão do Firestore mudou. Quem pedir
  /// durante um download recebe o resultado dele.
  Future<ResultadoConteudo> baixarConteudo() =>
      _baixando ??= _baixarConteudo().whenComplete(() => _baixando = null);

  Future<ResultadoConteudo> _baixarConteudo() async {
    final firestore = _firestore;
    if (firestore == null) return ResultadoConteudo.igual;
    try {
      if (!await _conectividade.online()) return ResultadoConteudo.falhou;
      final meta =
          (await firestore
                  .collection('meta')
                  .doc('conteudo')
                  .get()
                  .timeout(_esperaEnvio))
              .data();
      if (meta == null) return ResultadoConteudo.igual;
      final versao = meta['versao'] as int;
      if (versao == await _preferencias.lerVersaoBanco()) {
        return ResultadoConteudo.igual;
      }

      final db = await _banco.db;
      final materias = await firestore
          .collection('materias')
          .get()
          .timeout(_esperaEnvio);
      await aplicarConteudo(
        db,
        PacoteConteudo.deDocumentos(meta, [
          for (final d in materias.docs) d.data(),
        ], const []),
      );

      // Cada página fica gravada: se a rede cair, a próxima tentativa segue
      // da última questão aplicada.
      while (true) {
        final cursor = await _preferencias.lerUltimaSincronizacaoConteudo();
        var consulta = firestore
            .collection('questoes')
            .orderBy('atualizado_em');
        if (cursor != null) consulta = consulta.startAfter([cursor]);
        final pagina = await consulta
            .limit(tamanhoPaginaConteudo)
            .get()
            .timeout(_esperaEnvio);
        if (pagina.docs.isEmpty) break;

        final questoes = [for (final d in pagina.docs) d.data()];
        await aplicarConteudo(
          db,
          PacoteConteudo.deDocumentos({'versao': versao}, const [], questoes),
        );
        await _preferencias.gravarUltimaSincronizacaoConteudo(
          questoes.last['atualizado_em'] as String,
        );
        if (pagina.docs.length < tamanhoPaginaConteudo) break;
      }
      await _preferencias.gravarVersaoBanco(versao);
      return ResultadoConteudo.atualizado;
    } catch (erro) {
      debugPrint('Conteúdo não baixado: $erro');
      return ResultadoConteudo.falhou;
    }
  }

  bool _enviandoAdmin = false;
  bool _repetirAdmin = false;

  /// Sobe matérias e questões que o admin mudou no aparelho
  /// (`sincronizado = 0`) e a nova `meta/conteudo.versao`, numa transação.
  /// Devolve quantos documentos subiram, 0 se não havia nada ou -1 se falhou;
  /// na falha nada muda no aparelho e a próxima tentativa manda tudo de novo.
  Future<int> enviarConteudoAdmin(Usuario usuario) async {
    final firestore = _firestore;
    if (firestore == null || !usuario.isAdmin) return 0;
    if (_enviandoAdmin) {
      _repetirAdmin = true;
      return 0;
    }
    _enviandoAdmin = true;
    try {
      if (!await _conectividade.online()) return -1;
      return await _enviarConteudoAdmin(firestore);
    } catch (erro) {
      debugPrint('Conteúdo do admin não enviado: $erro');
      return -1;
    } finally {
      _enviandoAdmin = false;
      if (_repetirAdmin) {
        _repetirAdmin = false;
        unawaited(enviarConteudoAdmin(usuario));
      }
    }
  }

  Future<int> _enviarConteudoAdmin(FirebaseFirestore firestore) async {
    final db = await _banco.db;
    final materias = await db.query('Materia', where: 'sincronizado = 0');
    final questoes = await db.query('Questao', where: 'sincronizado = 0');
    if (materias.isEmpty && questoes.isEmpty) return 0;

    final assuntos = await db.query('Assunto', orderBy: 'id');
    final arestas = await db.query(
      'Grafo_Dependencia',
      orderBy: 'id_prerequisito, id_dependente',
    );
    final materiaDoAssunto = {
      for (final a in assuntos) a['id'] as int: a['id_materia'] as int,
    };
    Map<String, Object?> aresta(Map<String, Object?> a) => {
      'pre': a['id_prerequisito'],
      'dep': a['id_dependente'],
      'peso': a['peso'],
    };
    bool interna(Map<String, Object?> a) =>
        materiaDoAssunto[a['id_prerequisito']] ==
        materiaDoAssunto[a['id_dependente']];

    final docsMaterias = {
      for (final m in materias)
        m['id'] as int: <String, Object?>{
          'id': m['id'],
          'nome': m['nome'],
          'area': m['area'],
          'ativo': m['ativo'] == 1,
          'assuntos': [
            for (final a in assuntos)
              if (a['id_materia'] == m['id'])
                {
                  'id': a['id'],
                  'nome': a['nome'],
                  'descricao': a['descricao'],
                  'ativo': a['ativo'] == 1,
                },
          ],
          'dependencias': [
            for (final a in arestas)
              if (interna(a) &&
                  materiaDoAssunto[a['id_prerequisito']] == m['id'])
                aresta(a),
          ],
        },
    };

    final alternativas = <int, List<Map<String, Object?>>>{};
    if (questoes.isNotEmpty) {
      final ids = questoes.map((q) => q['id']).toList();
      for (final a in await db.query(
        'Alternativa',
        where: 'id_questao IN (${ids.map((_) => '?').join(', ')})',
        whereArgs: ids,
        orderBy: 'letra',
      )) {
        (alternativas[a['id_questao'] as int] ??= []).add({
          'letra': a['letra'],
          'texto': a['texto'],
          'correta': a['correta'] == 1,
          'imagem': a['imagem_url'],
          'imagem_descricao': a['imagem_descricao'],
        });
      }
    }

    // `atualizado_em` novo e único por questão, depois do cursor do aparelho:
    // é por ele que os outros aparelhos paginam o download.
    final cursor = await _preferencias.lerUltimaSincronizacaoConteudo();
    var relogio = DateTime.now().toUtc();
    final depoisDoCursor = cursor == null ? null : DateTime.tryParse(cursor);
    if (depoisDoCursor != null && !relogio.isAfter(depoisDoCursor)) {
      relogio = depoisDoCursor.toUtc();
    }
    String carimbo() {
      relogio = relogio.add(const Duration(milliseconds: 1));
      return '${relogio.toIso8601String().substring(0, 23)}Z';
    }

    final docsQuestoes = {
      for (final q in questoes)
        q['id'] as int: <String, Object?>{
          'id': q['id'],
          'materia': materiaDoAssunto[q['id_assunto']],
          'assunto': q['id_assunto'],
          'dificuldade': q['dificuldade'],
          'enunciado': q['enunciado'],
          'explicacao': q['explicacao'],
          'imagem': q['imagem_url'],
          'imagem_descricao': q['imagem_descricao'],
          'fonte': q['fonte'],
          'explicacao_gerada': q['explicacao_gerada'] == 1,
          'revisado': q['revisado'] == 1,
          'ativo': q['ativo'] == 1,
          'atualizado_em': carimbo(),
          'alternativas': alternativas[q['id']] ?? const [],
        },
    };

    // Diferença no total de ativas, a partir do que já está na nuvem.
    final colecaoQuestoes = firestore.collection('questoes');
    final antes = await Future.wait([
      for (final id in docsQuestoes.keys)
        colecaoQuestoes.doc('$id').get().timeout(_esperaEnvio),
    ]);
    var diferenca = 0;
    for (final doc in antes) {
      final eraAtiva = doc.data()?['ativo'] as bool? ?? false;
      final ficaAtiva = docsQuestoes[int.parse(doc.id)]!['ativo'] as bool;
      diferenca += (ficaAtiva ? 1 : 0) - (eraAtiva ? 1 : 0);
    }

    // A transação aceita 500 escritas: o excedente de questões sobe antes,
    // em lotes, e a versão só muda na transação, por último.
    final itensQuestoes = docsQuestoes.entries.toList();
    final naTransacao = itensQuestoes.take(_tamanhoLote).toList();
    final antecipadas = itensQuestoes.skip(_tamanhoLote).toList();
    for (var i = 0; i < antecipadas.length; i += _tamanhoLote) {
      final lote = firestore.batch();
      for (final e in antecipadas.skip(i).take(_tamanhoLote)) {
        lote.set(
          colecaoQuestoes.doc('${e.key}'),
          e.value,
          SetOptions(merge: true),
        );
      }
      await lote.commit().timeout(_esperaEnvio);
    }

    final refMeta = firestore.collection('meta').doc('conteudo');
    final versaoLocal = await _preferencias.lerVersaoBanco();
    final (anterior, nova) = await firestore
        .runTransaction((txn) async {
          final meta = (await txn.get(refMeta)).data() ?? const {};
          final anterior = meta['versao'] as int? ?? 0;
          final nova = anterior + 1;
          for (final e in docsMaterias.entries) {
            txn.set(firestore.collection('materias').doc('${e.key}'), e.value);
          }
          for (final e in naTransacao) {
            txn.set(
              colecaoQuestoes.doc('${e.key}'),
              e.value,
              SetOptions(merge: true),
            );
          }
          txn.set(refMeta, {
            'versao': nova,
            'atualizado_em': carimbo(),
            'total_questoes':
                ((meta['total_questoes'] as int?) ?? 0) + diferenca,
            if (docsMaterias.isNotEmpty)
              'dependencias_entre_materias': [
                for (final a in arestas)
                  if (!interna(a)) aresta(a),
              ],
          }, SetOptions(merge: true));
          return (anterior, nova);
        })
        .timeout(_esperaEnvio);

    // Só marca o que não mudou de novo durante o envio.
    final lote = db.batch();
    for (final (tabela, linhas) in [
      ('Materia', materias),
      ('Questao', questoes),
    ]) {
      for (final l in linhas) {
        lote.update(
          tabela,
          {'sincronizado': 1},
          where: l['atualizado_em'] == null
              ? 'id = ? AND atualizado_em IS NULL'
              : 'id = ? AND atualizado_em = ?',
          whereArgs: [l['id'], ?l['atualizado_em']],
        );
      }
    }
    await lote.commit(noResult: true);

    // O aparelho estava em dia com a versão anterior: a nova é a dele, e não
    // há por que baixá-la. Senão, o download normal traz o que faltava.
    if (versaoLocal == anterior) {
      await _preferencias.gravarVersaoBanco(nova);
      if (docsQuestoes.isNotEmpty) {
        await _preferencias.gravarUltimaSincronizacaoConteudo(
          docsQuestoes.values.last['atualizado_em'] as String,
        );
      }
    }
    if ((await _preferencias.lerVersaoConteudo() ?? 0) < nova) {
      await _preferencias.marcarSeedConcluido(nova);
    }
    return docsMaterias.length + docsQuestoes.length;
  }

  /// Sobe os pendentes do usuário. Devolve `true` se terminou tudo. Pedido
  /// feito durante um envio roda em seguida, para pegar o que entrou depois.
  Future<bool> sincronizar(Usuario usuario) async {
    final firestore = _firestore;
    final uid = usuario.uidFirebase;
    if (firestore == null || uid == null) return false;
    if (_rodando) {
      _repetir = true;
      return false;
    }

    _rodando = true;
    try {
      if (!await _conectividade.online()) return false;
      final raiz = firestore.collection('usuarios').doc(uid);
      await _subirHistorico(firestore, raiz, usuario.id);
      await _subirComConflito(
        firestore,
        raiz.collection('memoria'),
        'Nivel_Memoria',
        usuario.id,
        _camposMemoria,
      );
      await _subirComConflito(
        firestore,
        raiz.collection('proficiencia'),
        'Proficiencia',
        usuario.id,
        _camposProficiencia,
      );
      await _preferencias.gravarUltimaSincronizacao(DateTime.now());
      return true;
    } catch (_) {
      return false;
    } finally {
      _rodando = false;
      if (_repetir) {
        _repetir = false;
        unawaited(sincronizar(usuario));
      }
    }
  }

  static const _camposMemoria = [
    'retencao_atual',
    'data_ultimo_estudo',
    'qtd_revisoes',
    'atualizado_em',
  ];

  static const _camposProficiencia = [
    'nivel_estimado',
    'data_atualizacao',
    'atualizado_em',
  ];

  Future<List<Map<String, Object?>>> _pendentes(
    String tabela,
    int idUsuario,
  ) async {
    final db = await _banco.db;
    return db.query(
      tabela,
      where: 'id_usuario = ? AND sincronizado = 0',
      whereArgs: [idUsuario],
    );
  }

  Future<void> _enviar(
    FirebaseFirestore firestore,
    List<(DocumentReference<Map<String, dynamic>>, Map<String, Object?>)> itens,
  ) async {
    for (var i = 0; i < itens.length; i += _tamanhoLote) {
      final lote = firestore.batch();
      for (final (doc, dados) in itens.skip(i).take(_tamanhoLote)) {
        lote.set(doc, dados);
      }
      await lote.commit().timeout(_esperaEnvio);
    }
  }

  Future<void> _subirHistorico(
    FirebaseFirestore firestore,
    DocumentReference<Map<String, dynamic>> raiz,
    int idUsuario,
  ) async {
    final linhas = await _pendentes('Historico_Estudo', idUsuario);
    await _enviar(firestore, [
      for (final l in linhas)
        (
          raiz.collection('historico').doc(l['id'] as String),
          {
            'id_questao': l['id_questao'],
            'letra_escolhida': l['letra_escolhida'],
            'acertou': l['acertou'],
            'data': l['data'],
            'tempo_gasto': l['tempo_gasto'],
            'atualizado_em': l['atualizado_em'],
          },
        ),
    ]);
    final db = await _banco.db;
    final lote = db.batch();
    for (final l in linhas) {
      lote.update(
        'Historico_Estudo',
        {'sincronizado': 1},
        where: 'id = ? AND atualizado_em = ?',
        whereArgs: [l['id'], l['atualizado_em']],
      );
    }
    await lote.commit(noResult: true);
  }

  /// Memória e proficiência: vence o `atualizado_em` mais recente. A marcação
  /// confere a data para não apagar uma alteração feita durante o envio.
  Future<void> _subirComConflito(
    FirebaseFirestore firestore,
    CollectionReference<Map<String, dynamic>> colecao,
    String tabela,
    int idUsuario,
    List<String> campos,
  ) async {
    final db = await _banco.db;
    final envios =
        <(DocumentReference<Map<String, dynamic>>, Map<String, Object?>)>[];
    final enviadas = <Map<String, Object?>>[];

    for (final linha in await _pendentes(tabela, idUsuario)) {
      final doc = colecao.doc('${linha['id_assunto']}');
      final remoto = (await doc.get().timeout(_esperaEnvio)).data();
      final dataRemota = remoto?['atualizado_em'] as String?;
      final dataLocal = linha['atualizado_em'] as String;

      if (dataRemota != null && dataRemota.compareTo(dataLocal) > 0) {
        await db.update(
          tabela,
          {for (final c in campos) c: remoto![c], 'sincronizado': 1},
          where: 'id_usuario = ? AND id_assunto = ?',
          whereArgs: [idUsuario, linha['id_assunto']],
        );
      } else {
        envios.add((doc, {for (final c in campos) c: linha[c]}));
        enviadas.add(linha);
      }
    }

    await _enviar(firestore, envios);
    for (final l in enviadas) {
      await db.update(
        tabela,
        {'sincronizado': 1},
        where: 'id_usuario = ? AND id_assunto = ? AND atualizado_em = ?',
        whereArgs: [idUsuario, l['id_assunto'], l['atualizado_em']],
      );
    }
  }

  /// Traz da nuvem o progresso de uma conta que este aparelho ainda não viu.
  Future<void> baixarProgresso(Usuario usuario) async {
    final firestore = _firestore;
    final uid = usuario.uidFirebase;
    if (firestore == null || uid == null) return;
    try {
      final raiz = firestore.collection('usuarios').doc(uid);
      final historico = await raiz
          .collection('historico')
          .get()
          .timeout(_esperaEnvio);
      final memoria = await raiz
          .collection('memoria')
          .get()
          .timeout(_esperaEnvio);
      final proficiencia = await raiz
          .collection('proficiencia')
          .get()
          .timeout(_esperaEnvio);

      final db = await _banco.db;
      await db.transaction((txn) async {
        final lote = txn.batch();
        for (final doc in historico.docs) {
          lote.insert('Historico_Estudo', {
            ...doc.data(),
            'id': doc.id,
            'id_usuario': usuario.id,
            'sincronizado': 1,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        for (final doc in memoria.docs) {
          lote.insert('Nivel_Memoria', {
            ...doc.data(),
            'id_usuario': usuario.id,
            'id_assunto': int.parse(doc.id),
            'sincronizado': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final doc in proficiencia.docs) {
          lote.insert('Proficiencia', {
            ...doc.data(),
            'id_usuario': usuario.id,
            'id_assunto': int.parse(doc.id),
            'sincronizado': 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await lote.commit(noResult: true);
      });
    } catch (_) {
      // Sem rede agora: a conta abre vazia neste aparelho, sem quebrar o app.
    }
  }

  Future<int> contarPendentes(int idUsuario) async {
    final db = await _banco.db;
    final linhas = await db.rawQuery(
      '''
SELECT (SELECT COUNT(*) FROM Historico_Estudo WHERE id_usuario = ?1 AND sincronizado = 0)
     + (SELECT COUNT(*) FROM Nivel_Memoria WHERE id_usuario = ?1 AND sincronizado = 0)
     + (SELECT COUNT(*) FROM Proficiencia WHERE id_usuario = ?1 AND sincronizado = 0) AS n''',
      [idUsuario],
    );
    return linhas.first['n'] as int;
  }
}

final conectividadeProvider = Provider<Conectividade>(
  (_) => ConectividadePlus(),
);

final servicoSincronizacaoProvider = Provider<ServicoSincronizacao>(
  (ref) => ServicoSincronizacao(
    ref.watch(bancoProvider),
    ref.watch(firestoreProvider),
    ref.watch(preferenciasProvider),
    ref.watch(conectividadeProvider),
  ),
);

/// O que o Perfil mostra sobre a nuvem.
class StatusSincronizacao {
  final bool online;
  final int pendentes;
  final DateTime? ultima;
  const StatusSincronizacao({
    required this.online,
    required this.pendentes,
    required this.ultima,
  });

  String texto(DateTime agora) {
    if (!online) return 'Offline — $pendentes pendentes';
    if (pendentes > 0) return '$pendentes pendentes para enviar';
    if (ultima == null) return 'Ainda não sincronizado';
    final minutos = agora.difference(ultima!).inMinutes;
    return minutos < 1 ? 'Sincronizado agora' : 'Sincronizado há $minutos min';
  }
}

/// Sobe quando uma sincronização termina, para o Perfil reler o status.
final versaoSincronizacaoProvider = StateProvider<int>((_) => 0);

final statusSincronizacaoProvider = FutureProvider<StatusSincronizacao>((
  ref,
) async {
  ref.watch(versaoSincronizacaoProvider);
  ref.watch(historicoProvider);
  final usuario = ref.watch(usuarioProvider);
  final servico = ref.watch(servicoSincronizacaoProvider);
  return StatusSincronizacao(
    online: await ref.watch(conectividadeProvider).online(),
    pendentes: usuario == null ? 0 : await servico.contarPendentes(usuario.id),
    ultima: await ref.watch(preferenciasProvider).lerUltimaSincronizacao(),
  );
});

/// Versão do banco de questões no aparelho, para o Perfil.
final versaoBancoProvider = FutureProvider<int>((ref) async {
  ref.watch(conteudoProvider);
  final preferencias = ref.watch(preferenciasProvider);
  return await preferencias.lerVersaoBanco() ??
      await preferencias.lerVersaoConteudo() ??
      0;
});

/// Baixa o conteúdo e faz as telas relerem o banco, se ele mudou.
Future<ResultadoConteudo> atualizarConteudo(Ref ref) async {
  final resultado = await ref
      .read(servicoSincronizacaoProvider)
      .baixarConteudo();
  if (resultado == ResultadoConteudo.atualizado) {
    ref.invalidate(conteudoProvider);
    ref.invalidate(dependenciasProvider);
    ref.invalidate(grafoProvider);
  }
  return resultado;
}

/// Vincula o visitante, se preciso, traz o conteúdo novo e sobe os pendentes
/// do usuário atual. O conteúdo vem antes porque precisa do login, e [baixar]
/// fica falso a cada resposta, para não gastar uma leitura do Firestore.
Future<bool> sincronizarAgora(Ref ref, {bool baixar = true}) async {
  await ref.read(sessaoProvider.notifier).vincularVisitante();
  // O que o admin mudou sobe antes do download, que não o desfaz.
  if (baixar) await enviarConteudoAdmin(ref);
  final conteudo = baixar
      ? await atualizarConteudo(ref)
      : ResultadoConteudo.igual;
  final usuario = ref.read(usuarioProvider);
  if (usuario == null) return false;
  final terminou = await ref
      .read(servicoSincronizacaoProvider)
      .sincronizar(usuario);
  ref.read(versaoSincronizacaoProvider.notifier).state++;
  return terminou && conteudo != ResultadoConteudo.falhou;
}

/// Para as telas pedirem uma sincronização depois de cada resposta.
final acaoSincronizarProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => sincronizarAgora(ref, baixar: false),
);

/// Mantém a sincronização rodando: ao abrir o app, ao trocar de usuário e
/// quando a internet volta. Sem Firebase, não faz nada.
final sincronizadorProvider = Provider<void>((ref) {
  if (ref.watch(firestoreProvider) == null) return;

  ref.listen(usuarioProvider, (anterior, atual) {
    if (atual == null) return;
    if (anterior?.id != atual.id ||
        anterior?.uidFirebase != atual.uidFirebase) {
      sincronizarAgora(ref);
    }
  }, fireImmediately: true);

  final assinatura = ref.watch(conectividadeProvider).mudancas.listen((online) {
    ref.read(versaoSincronizacaoProvider.notifier).state++;
    if (online) repetirAteConseguir(() => sincronizarAgora(ref));
  });
  ref.onDispose(assinatura.cancel);
});

/// Sobe as alterações do painel admin sem a tela esperar. Quando algo subiu,
/// as telas releem o banco para apagar os ícones de pendente.
Future<void> enviarConteudoAdmin(Ref ref) async {
  final usuario = ref.read(usuarioProvider);
  if (usuario == null || !usuario.isAdmin) return;
  final enviados = await ref
      .read(servicoSincronizacaoProvider)
      .enviarConteudoAdmin(usuario);
  if (enviados > 0) ref.invalidate(conteudoProvider);
}
