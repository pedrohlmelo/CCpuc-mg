import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../banco/banco_local.dart';
import '../estado_app.dart';
import '../firebase.dart';
import '../modelos.dart';
import '../preferencias.dart';

/// Tamanho de cada lote: o Firestore aceita até 500 escritas por `WriteBatch`.
const _tamanhoLote = 400;

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

/// Copia o progresso do SQLite para `usuarios/{uid}/...`. O SQLite continua
/// sendo a fonte de verdade: nenhuma falha aqui atrapalha o estudo.
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

/// Vincula o visitante, se preciso, e sobe os pendentes do usuário atual.
Future<bool> sincronizarAgora(Ref ref) async {
  await ref.read(sessaoProvider.notifier).vincularVisitante();
  final usuario = ref.read(usuarioProvider);
  if (usuario == null) return false;
  final terminou = await ref
      .read(servicoSincronizacaoProvider)
      .sincronizar(usuario);
  ref.read(versaoSincronizacaoProvider.notifier).state++;
  return terminou;
}

/// Para as telas pedirem uma sincronização depois de cada resposta.
final acaoSincronizarProvider = Provider<Future<void> Function()>(
  (ref) =>
      () => sincronizarAgora(ref),
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
