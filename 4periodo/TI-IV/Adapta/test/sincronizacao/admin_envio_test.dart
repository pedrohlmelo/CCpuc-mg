import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/banco/pacote_inicial.g.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/preferencias.dart';
import 'package:adapta/dados/repositorios/admin_conteudo_repositorio.dart';
import 'package:adapta/dados/repositorios/conteudo_repositorio.dart';
import 'package:adapta/dados/sincronizacao/servico_sincronizacao.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';
import '../repositorios/admin_conteudo_test.dart' show questaoNova;

const _admin = Usuario(
  id: 1,
  uidFirebase: 'adm',
  nome: 'Admin',
  email: 'admin@adapta.app',
  tipo: TipoUsuario.admin,
);

/// Firestore que recusa a transação, como as regras ou a rede fariam.
class _FirestoreQueFalha extends FakeFirebaseFirestore {
  bool falhar = true;

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    if (falhar) throw FirebaseException(plugin: 'teste', code: 'unavailable');
    return super.runTransaction(
      transactionHandler,
      timeout: timeout,
      maxAttempts: maxAttempts,
    );
  }
}

void main() {
  const preferencias = Preferencias();
  late BancoLocal banco;
  late _FirestoreQueFalha firestore;
  late ConectividadeFalsa rede;
  late ServicoSincronizacao servico;
  late AdminConteudoRepositorio admin;

  /// O Firestore igual ao pacote inicial, na versão dele.
  Future<void> publicarPacote() async {
    for (final m in pacoteInicialMaterias) {
      await firestore.collection('materias').doc('${m['id']}').set(m);
    }
    for (final q in pacoteInicialQuestoes) {
      await firestore.collection('questoes').doc('${q['id']}').set(q);
    }
    await firestore.collection('meta').doc('conteudo').set(pacoteInicialMeta);
  }

  final versaoPacote = pacoteInicialMeta['versao'] as int;
  final totalPacote = pacoteInicialMeta['total_questoes'] as int;

  Future<Map<String, dynamic>?> doc(String colecao, Object id) async =>
      (await firestore.collection(colecao).doc('$id').get()).data();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    firestore = _FirestoreQueFalha()..falhar = false;
    rede = ConectividadeFalsa(conectado: true);
    servico = ServicoSincronizacao(banco, firestore, preferencias, rede);
    admin = AdminConteudoRepositorio(banco, usuarioAtual: () => _admin);
    await publicarPacote();
    await banco.db;
    // O aparelho do admin já está em dia com o Firestore.
    await preferencias.gravarVersaoBanco(versaoPacote);
  });

  tearDown(() => banco.fechar());

  test('matéria e questão criadas online sobem e a versão aumenta', () async {
    final idMateria = await admin.criarMateria('Nova matéria X', 'natureza');
    final idAssunto = await admin.criarAssunto(idMateria, 'Assunto teste', '');
    final idQuestao = await admin.salvarQuestao(
      questaoNova(idAssunto: idAssunto),
    );

    expect(await servico.enviarConteudoAdmin(_admin), 2);

    final materia = (await doc('materias', idMateria))!;
    expect(materia['nome'], 'Nova matéria X');
    expect(materia['ativo'], isTrue);
    expect((materia['assuntos'] as List).single['id'], idAssunto);
    final questao = (await doc('questoes', idQuestao))!;
    expect(questao['assunto'], idAssunto);
    expect(questao['materia'], idMateria);
    expect(questao['fonte'], fonteAutoral);
    expect(questao['alternativas'], hasLength(5));
    expect(questao['atualizado_em'], isA<String>());

    final meta = (await doc('meta', 'conteudo'))!;
    expect(meta['versao'], versaoPacote + 1);
    expect(meta['total_questoes'], totalPacote + 1);
    expect(await admin.contarPendentes(), 0);
    expect(await preferencias.lerVersaoBanco(), versaoPacote + 1);
    expect(
      await preferencias.lerUltimaSincronizacaoConteudo(),
      questao['atualizado_em'],
    );
    // Já está em dia: não baixa de novo.
    expect(await servico.baixarConteudo(), ResultadoConteudo.igual);
  });

  test('pendentes criados offline sobem quando a rede volta', () async {
    rede.conectado = false;
    await admin.editarMateria(1, 'Matemática offline', 'matematica');
    await admin.salvarQuestao(questaoNova());

    expect(await servico.enviarConteudoAdmin(_admin), -1);
    expect(await admin.contarPendentes(), 2);
    expect((await doc('materias', 1))!['nome'], 'Matemática');

    rede.conectado = true;
    expect(await servico.enviarConteudoAdmin(_admin), 2);
    expect(await admin.contarPendentes(), 0);
    expect((await doc('materias', 1))!['nome'], 'Matemática offline');
    expect((await doc('meta', 'conteudo'))!['versao'], versaoPacote + 1);
  });

  test('falha no Firestore mantém tudo pendente', () async {
    firestore.falhar = true;
    await admin.salvarQuestao(questaoNova());

    expect(await servico.enviarConteudoAdmin(_admin), -1);
    expect(await admin.contarPendentes(), 1);
    expect((await doc('meta', 'conteudo'))!['versao'], versaoPacote);
    expect(await preferencias.lerVersaoBanco(), versaoPacote);

    firestore.falhar = false;
    expect(await servico.enviarConteudoAdmin(_admin), 1);
    expect(await admin.contarPendentes(), 0);
  });

  test('aluno não envia nada', () async {
    await admin.salvarQuestao(questaoNova());
    const aluno = Usuario(id: 2, uidFirebase: 'a', nome: 'Ana');
    expect(await servico.enviarConteudoAdmin(aluno), 0);
    expect(await admin.contarPendentes(), 1);
  });

  test('excluir matéria sobe a matéria inativa e as questões dela', () async {
    final impacto = await admin.impactoMateria(7);
    await admin.excluirMateria(7);

    expect(await servico.enviarConteudoAdmin(_admin), greaterThan(1));

    final quimica = (await doc('materias', 7))!;
    expect(quimica['ativo'], isFalse);
    expect(
      (quimica['assuntos'] as List).every((a) => a['ativo'] == false),
      isTrue,
    );
    final meta = (await doc('meta', 'conteudo'))!;
    expect(
      (meta['dependencias_entre_materias'] as List).any(
        (d) => d['dep'] == 701 || d['pre'] == 701,
      ),
      isFalse,
    );
    expect(meta['total_questoes'], totalPacote - impacto.questoes);
  });

  test('download depois do envio não desfaz a mudança', () async {
    await admin.editarMateria(1, 'Matemática nova', 'matematica');
    final id = await admin.salvarQuestao(questaoNova(enunciado: 'Local'));
    expect(await servico.enviarConteudoAdmin(_admin), 2);

    // Força um download completo, como num aparelho fora de dia.
    await preferencias.reiniciarDownloadConteudo();
    expect(await servico.baixarConteudo(), ResultadoConteudo.atualizado);

    final conteudo = await ConteudoRepositorio(banco).carregar();
    expect(conteudo.materiaPorId(1)?.nome, 'Matemática nova');
    expect(conteudo.questaoPorId(id)?.enunciado, 'Local');
    expect(conteudo.questaoPorId(id)?.pendente, isFalse);
  });

  test('outro aparelho, de aluno, baixa a matéria e a questão novas', () async {
    final idMateria = await admin.criarMateria('Nova matéria X', 'natureza');
    final idAssunto = await admin.criarAssunto(idMateria, 'Assunto teste', '');
    final idQuestao = await admin.salvarQuestao(
      questaoNova(idAssunto: idAssunto, enunciado: 'Questão nova'),
    );
    expect(await servico.enviarConteudoAdmin(_admin), 2);

    // Outro aparelho: banco e preferências próprios.
    SharedPreferences.setMockInitialValues({});
    final outroBanco = bancoDeTeste();
    addTearDown(outroBanco.fechar);
    final outro = ServicoSincronizacao(
      outroBanco,
      firestore,
      preferencias,
      rede,
    );
    await outroBanco.db;

    expect(await outro.baixarConteudo(), ResultadoConteudo.atualizado);

    final conteudo = await ConteudoRepositorio(outroBanco).carregar();
    expect(conteudo.materias.any((m) => m.nome == 'Nova matéria X'), isTrue);
    final questao = conteudo.questoes.firstWhere((q) => q.id == idQuestao);
    expect(questao.enunciado, 'Questão nova');
    expect(questao.gabarito.letra, 'C');
  });

  test('envio pedido durante outro envio roda em seguida', () async {
    await admin.salvarQuestao(questaoNova());
    final primeiro = servico.enviarConteudoAdmin(_admin);
    await admin.salvarQuestao(questaoNova(enunciado: 'Segunda'));
    expect(await servico.enviarConteudoAdmin(_admin), 0);
    await primeiro;
    // A repetição roda sozinha logo depois.
    for (var i = 0; i < 50 && await admin.contarPendentes() > 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(await admin.contarPendentes(), 0);
  });
}
