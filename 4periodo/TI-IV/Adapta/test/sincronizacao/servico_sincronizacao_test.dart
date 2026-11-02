import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/preferencias.dart';
import 'package:adapta/dados/repositorios/aprendizado_repositorio.dart';
import 'package:adapta/dados/repositorios/historico_repositorio.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:adapta/dados/sincronizacao/servico_sincronizacao.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

void main() {
  late BancoLocal banco;
  late FakeFirebaseFirestore firestore;
  late ConectividadeFalsa rede;
  late ServicoSincronizacao servico;
  late Usuario usuario;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    firestore = FakeFirebaseFirestore();
    rede = ConectividadeFalsa(conectado: true);
    servico = ServicoSincronizacao(
      banco,
      firestore,
      const Preferencias(),
      rede,
    );
    usuario = await UsuarioRepositorio(banco).criarVisitante(uid: 'u1');
  });

  tearDown(() => banco.fechar());

  Future<void> responder() => HistoricoRepositorio(banco).registrar(
    idUsuario: usuario.id,
    idQuestao: 1,
    letra: 'B',
    acertou: true,
    tempoGasto: 9,
  );

  Future<void> estudar(double retencao) =>
      AprendizadoRepositorio(banco).salvarMemoria(
        usuario.id,
        NivelMemoria(
          idAssunto: 1,
          retencao: retencao,
          ultimoEstudo: DateTime(2026, 11, 1),
          qtdRevisoes: 1,
        ),
      );

  test('pendentes sobem e viram sincronizados', () async {
    await responder();
    await estudar(0.6);
    await AprendizadoRepositorio(banco).salvarProficiencia(usuario.id, 1, 0.3);
    expect(await servico.contarPendentes(usuario.id), 3);

    expect(await servico.sincronizar(usuario), isTrue);

    expect(await servico.contarPendentes(usuario.id), 0);
    final raiz = firestore.collection('usuarios').doc('u1');
    final historico = await raiz.collection('historico').get();
    expect(historico.docs.single.data()['id_questao'], 1);
    final memoria = await raiz.collection('memoria').doc('1').get();
    expect(memoria.data()?['retencao_atual'], 0.6);
    final proficiencia = await raiz.collection('proficiencia').doc('1').get();
    expect(proficiencia.data()?['nivel_estimado'], 0.3);
    expect(await const Preferencias().lerUltimaSincronizacao(), isNotNull);
  });

  test('offline não quebra e mantém tudo pendente', () async {
    rede.conectado = false;
    await responder();

    expect(await servico.sincronizar(usuario), isFalse);

    expect(await servico.contarPendentes(usuario.id), 1);
    final docs = await firestore.collectionGroup('historico').get();
    expect(docs.docs, isEmpty);
  });

  test('pedido durante um envio roda em seguida', () async {
    await responder();
    final primeiro = servico.sincronizar(usuario);
    await responder();
    expect(await servico.sincronizar(usuario), isFalse);
    await primeiro;
    await pumpEventQueue();

    expect(await servico.contarPendentes(usuario.id), 0);
    final historico = await firestore
        .collection('usuarios')
        .doc('u1')
        .collection('historico')
        .get();
    expect(historico.docs, hasLength(2));
  });

  test('repete até a rede responder de verdade', () async {
    var tentativas = 0;
    await repetirAteConseguir(
      () async => ++tentativas == 3,
      esperas: const [Duration.zero, Duration.zero, Duration.zero],
    );
    expect(tentativas, 3);
  });

  test('desiste depois da última espera', () async {
    var tentativas = 0;
    await repetirAteConseguir(() async {
      tentativas++;
      return false;
    }, esperas: const [Duration.zero]);
    expect(tentativas, 2);
  });

  test('visitante sem uid espera o login anônimo', () async {
    final semUid = await UsuarioRepositorio(banco).criarVisitante();
    expect(await servico.sincronizar(semUid), isFalse);
  });

  test('no conflito, a nuvem mais recente vence', () async {
    await estudar(0.6);
    final doc = firestore
        .collection('usuarios')
        .doc('u1')
        .collection('memoria')
        .doc('1');
    await doc.set({
      'retencao_atual': 0.9,
      'data_ultimo_estudo': '2026-12-01T00:00:00.000',
      'qtd_revisoes': 7,
      'atualizado_em': '2999-01-01T00:00:00.000',
    });

    await servico.sincronizar(usuario);

    final local = await AprendizadoRepositorio(banco).memorias(usuario.id);
    expect(local.single.retencao, 0.9);
    expect(local.single.qtdRevisoes, 7);
    expect((await doc.get()).data()?['retencao_atual'], 0.9);
    expect(await servico.contarPendentes(usuario.id), 0);
  });

  test('no conflito, o aparelho mais recente vence', () async {
    await estudar(0.6);
    final doc = firestore
        .collection('usuarios')
        .doc('u1')
        .collection('memoria')
        .doc('1');
    await doc.set({
      'retencao_atual': 0.9,
      'data_ultimo_estudo': '2020-01-01T00:00:00.000',
      'qtd_revisoes': 7,
      'atualizado_em': '2020-01-01T00:00:00.000',
    });

    await servico.sincronizar(usuario);

    expect((await doc.get()).data()?['retencao_atual'], 0.6);
  });

  test('login em outro aparelho baixa o progresso', () async {
    await responder();
    await estudar(0.6);
    await servico.sincronizar(usuario);

    final outroBanco = bancoDeTeste();
    addTearDown(outroBanco.fechar);
    final outro = await UsuarioRepositorio(
      outroBanco,
    ).criarVisitante(uid: 'u1');
    await ServicoSincronizacao(
      outroBanco,
      firestore,
      const Preferencias(),
      rede,
    ).baixarProgresso(outro);

    expect(
      await HistoricoRepositorio(outroBanco).listar(outro.id),
      hasLength(1),
    );
    final memorias = await AprendizadoRepositorio(
      outroBanco,
    ).memorias(outro.id);
    expect(memorias.single.retencao, 0.6);
  });

  test('o texto do Perfil acompanha o estado', () {
    final agora = DateTime(2026, 11, 6, 10);
    expect(
      const StatusSincronizacao(
        online: false,
        pendentes: 3,
        ultima: null,
      ).texto(agora),
      'Offline — 3 pendentes',
    );
    expect(
      StatusSincronizacao(
        online: true,
        pendentes: 0,
        ultima: agora.subtract(const Duration(minutes: 5)),
      ).texto(agora),
      'Sincronizado há 5 min',
    );
  });
}
