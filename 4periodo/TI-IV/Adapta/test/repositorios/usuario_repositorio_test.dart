import 'package:adapta/dados/banco/banco_local.dart';
import 'package:adapta/dados/modelos.dart';
import 'package:adapta/dados/repositorios/usuario_repositorio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../apoio/app_teste.dart';

void main() {
  late BancoLocal banco;
  late FakeFirebaseFirestore firestore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    banco = bancoDeTeste();
    firestore = FakeFirebaseFirestore();
  });

  tearDown(() => banco.fechar());

  UsuarioRepositorio repositorio(FirebaseAuth? auth) =>
      UsuarioRepositorio(banco, auth: auth, firestore: firestore);

  test('primeiro acesso online vira visitante anônimo com uid', () async {
    final usuario = await repositorio(MockFirebaseAuth()).sessaoInicial();
    expect(usuario.visitante, isTrue);
    expect(usuario.uidFirebase, isNotNull);
  });

  test('sem Firebase, o visitante é local e reaparece ao reabrir', () async {
    final primeiro = await repositorio(null).sessaoInicial();
    final segundo = await repositorio(null).sessaoInicial();
    expect(primeiro.uidFirebase, isNull);
    expect(segundo.id, primeiro.id);
  });

  test('offline no primeiro acesso: o uid chega quando a rede volta', () async {
    final auth = MockFirebaseAuth();
    whenCalling(
      Invocation.method(#signInAnonymously, null),
    ).on(auth).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    final offline = await repositorio(auth).sessaoInicial();
    expect(offline.uidFirebase, isNull);

    final online = await repositorio(
      MockFirebaseAuth(),
    ).vincularVisitante(offline);
    expect(online.id, offline.id);
    expect(online.uidFirebase, isNotNull);
  });

  test('cadastro mantém o usuário e grava nome e e-mail', () async {
    final anonimo = _AnonimoVinculavel();
    final repo = repositorio(
      MockFirebaseAuth(signedIn: true, mockUser: anonimo),
    );
    final visitante = await repo.sessaoInicial();

    final conta = await repo.cadastrar(
      visitante,
      nome: 'Ana Souza',
      email: 'ana@x.com',
      senha: '123456',
    );

    expect(conta.id, visitante.id);
    expect(conta.uidFirebase, visitante.uidFirebase);
    expect(conta.email, 'ana@x.com');
    expect(anonimo.vinculos, hasLength(1));
    final doc = await firestore
        .collection('usuarios')
        .doc(conta.uidFirebase)
        .get();
    expect(doc.data(), {
      'nome': 'Ana Souza',
      'email': 'ana@x.com',
      'tipo': 'aluno',
    });
  });

  test('login lê o tipo da nuvem e sabe se a conta é nova aqui', () async {
    await firestore.collection('usuarios').doc('adm').set({
      'nome': 'Administração',
      'email': 'admin@adapta.app',
      'tipo': 'admin',
    });
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'adm', email: 'admin@adapta.app'),
    );

    final primeira = await repositorio(auth).entrar('admin@adapta.app', 'x');
    expect(primeira.novo, isTrue);
    expect(primeira.usuario.tipo, TipoUsuario.admin);

    final segunda = await repositorio(auth).entrar('admin@adapta.app', 'x');
    expect(segunda.novo, isFalse);
    expect(segunda.usuario.id, primeira.usuario.id);
  });

  test('erro do Auth chega em português', () async {
    final auth = MockFirebaseAuth();
    whenCalling(
      Invocation.method(#signInWithEmailAndPassword, null),
    ).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    await expectLater(
      repositorio(auth).entrar('a@b.c', 'x'),
      throwsA(
        isA<ErroConta>().having(
          (e) => e.mensagem,
          'mensagem',
          'E-mail ou senha incorretos.',
        ),
      ),
    );
  });

  test('sem Firebase, cadastro e login explicam o motivo', () async {
    final visitante = await repositorio(null).sessaoInicial();
    await expectLater(
      repositorio(
        null,
      ).cadastrar(visitante, nome: 'A', email: 'a@b.c', senha: '123456'),
      throwsA(isA<ErroConta>()),
    );
    await expectLater(
      repositorio(null).entrar('a@b.c', '123456'),
      throwsA(isA<ErroConta>()),
    );
  });

  test('sair devolve um visitante novo', () async {
    final repo = repositorio(MockFirebaseAuth());
    final antes = await repo.sessaoInicial();
    final depois = await repo.sair();
    expect(depois.id, isNot(antes.id));
    expect(depois.visitante, isTrue);
  });
}

/// O `linkWithCredential` do mock recusa usuário anônimo por uma asserção
/// interna; aqui ele só registra a chamada, como o Firebase manteria o uid.
// ignore: must_be_immutable
class _AnonimoVinculavel extends MockUser {
  final vinculos = <AuthCredential>[];

  _AnonimoVinculavel() : super(isAnonymous: true, uid: 'anonimo');

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    vinculos.add(credential);
    return _Credencial();
  }
}

class _Credencial implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
