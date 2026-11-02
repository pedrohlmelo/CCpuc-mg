import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../banco/banco_local.dart';
import '../firebase.dart';
import '../modelos.dart';

const nomeVisitante = 'Visitante';

/// Sem rede, o Firebase pode demorar a desistir; o app não fica esperando.
const _esperaRede = Duration(seconds: 6);

/// Erro de conta com a mensagem pronta para a tela.
class ErroConta implements Exception {
  final String mensagem;
  const ErroConta(this.mensagem);

  @override
  String toString() => mensagem;
}

String mensagemDoAuth(FirebaseAuthException erro) => switch (erro.code) {
  'invalid-email' => 'Este e-mail não é válido.',
  'user-disabled' => 'Esta conta foi desativada.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' ||
  'INVALID_LOGIN_CREDENTIALS' => 'E-mail ou senha incorretos.',
  'email-already-in-use' ||
  'credential-already-in-use' => 'Já existe uma conta com este e-mail.',
  'weak-password' => 'A senha precisa de pelo menos 6 caracteres.',
  'network-request-failed' => 'Sem conexão. Tente de novo com internet.',
  'too-many-requests' => 'Muitas tentativas. Aguarde um pouco.',
  'operation-not-allowed' => 'Este tipo de acesso não está ativado.',
  _ => 'Não foi possível concluir agora. Tente de novo.',
};

/// Contas e sessão. A linha local em `Usuario` existe para todo mundo; a senha
/// é só do Firebase Auth. Sem [_auth] (Firebase fora do ar), tudo que não
/// depende de conta continua funcionando.
class UsuarioRepositorio {
  final BancoLocal _banco;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  UsuarioRepositorio(this._banco, {this._auth, this._firestore});

  Usuario _usuario(Map<String, Object?> l) => Usuario(
    id: l['id'] as int,
    uidFirebase: l['uid_firebase'] as String?,
    nome: l['nome'] as String,
    email: l['email'] as String?,
    tipo: l['tipo'] == 'admin' ? TipoUsuario.admin : TipoUsuario.aluno,
  );

  Future<Usuario> _porId(int id) async {
    final db = await _banco.db;
    final linhas = await db.query('Usuario', where: 'id = ?', whereArgs: [id]);
    return _usuario(linhas.single);
  }

  Future<Usuario?> _porUid(String uid) async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Usuario',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );
    return linhas.isEmpty ? null : _usuario(linhas.first);
  }

  /// Cria a linha de um visitante, com ou sem uid do Firebase.
  Future<Usuario> criarVisitante({String? uid}) async {
    final db = await _banco.db;
    final id = await db.insert('Usuario', {
      'uid_firebase': uid,
      'nome': nomeVisitante,
    });
    return Usuario(id: id, uidFirebase: uid, nome: nomeVisitante);
  }

  /// O último usuário criado é o da sessão enquanto não há login.
  Future<Usuario?> ultimoLocal() async {
    final db = await _banco.db;
    final linhas = await db.query('Usuario', orderBy: 'id DESC', limit: 1);
    return linhas.isEmpty ? null : _usuario(linhas.first);
  }

  /// Decide quem abre o app: a sessão do Firebase, se houver; senão, o
  /// visitante deste aparelho, com login anônimo quando houver internet.
  Future<Usuario> sessaoInicial() async {
    final auth = _auth;
    final ultimo = await ultimoLocal();
    if (auth == null) return ultimo ?? await criarVisitante();

    final atual = auth.currentUser;
    if (atual != null) {
      final local = await _porUid(atual.uid);
      if (local != null) return local;
      // A sessão sobreviveu, mas o banco é novo.
      if (ultimo != null && ultimo.uidFirebase == null && ultimo.visitante) {
        return _gravarUid(ultimo, atual.uid);
      }
      return criarVisitante(uid: atual.uid);
    }

    final semUid =
        ultimo != null && ultimo.uidFirebase == null && ultimo.visitante;
    final visitante = semUid ? ultimo : await criarVisitante();
    return vincularVisitante(visitante);
  }

  Future<Usuario> _gravarUid(Usuario usuario, String uid) async {
    final db = await _banco.db;
    await db.update(
      'Usuario',
      {'uid_firebase': uid},
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
    return _porId(usuario.id);
  }

  /// Faz o login anônimo do visitante criado offline. Sem internet, devolve o
  /// mesmo visitante: a sincronização chama de novo quando a rede voltar.
  Future<Usuario> vincularVisitante(Usuario usuario) async {
    final auth = _auth;
    if (auth == null || usuario.uidFirebase != null) return usuario;
    try {
      final uid =
          auth.currentUser?.uid ??
          (await auth.signInAnonymously().timeout(_esperaRede)).user?.uid;
      if (uid == null) return usuario;
      return await _porUid(uid) ?? await _gravarUid(usuario, uid);
    } on FirebaseAuthException {
      return usuario;
    } on TimeoutException {
      return usuario;
    }
  }

  /// Transforma o visitante em conta: o uid continua o mesmo, e com ele todo
  /// o progresso.
  Future<Usuario> cadastrar(
    Usuario atual, {
    required String nome,
    required String email,
    required String senha,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw const ErroConta('Criar conta precisa de conexão com a nuvem.');
    }
    try {
      final anonimo =
          auth.currentUser ?? (await auth.signInAnonymously()).user!;
      final credencial = EmailAuthProvider.credential(
        email: email,
        password: senha,
      );
      await anonimo.linkWithCredential(credencial).timeout(_esperaRede * 2);

      final db = await _banco.db;
      await db.update(
        'Usuario',
        {'uid_firebase': anonimo.uid, 'nome': nome, 'email': email},
        where: 'id = ?',
        whereArgs: [atual.id],
      );
      await _gravarPerfil(anonimo.uid, nome, email);
      return _porId(atual.id);
    } on FirebaseAuthException catch (erro) {
      throw ErroConta(mensagemDoAuth(erro));
    } on TimeoutException {
      throw const ErroConta('Sem conexão. Tente de novo com internet.');
    }
  }

  /// A cópia do perfil na nuvem é um extra: a conta já existe sem ela.
  Future<void> _gravarPerfil(String uid, String nome, String email) async {
    try {
      await _firestore
          ?.collection('usuarios')
          .doc(uid)
          .set({'nome': nome, 'email': email, 'tipo': 'aluno'})
          .timeout(_esperaRede);
    } catch (_) {
      // Fica sem o documento até o próximo acesso; o tipo padrão é aluno.
    }
  }

  Future<Map<String, dynamic>?> _lerPerfil(String uid) async {
    try {
      final doc = await _firestore
          ?.collection('usuarios')
          .doc(uid)
          .get()
          .timeout(_esperaRede);
      return doc?.data();
    } catch (_) {
      return null;
    }
  }

  /// Entra com e-mail e senha. `novo` indica que este aparelho ainda não
  /// conhece a conta, e o progresso dela precisa ser baixado da nuvem.
  Future<({Usuario usuario, bool novo})> entrar(
    String email,
    String senha,
  ) async {
    final auth = _auth;
    if (auth == null) {
      throw const ErroConta('Entrar precisa de conexão com a nuvem.');
    }
    final String uid;
    try {
      final credencial = await auth
          .signInWithEmailAndPassword(email: email, password: senha)
          .timeout(_esperaRede * 2);
      uid = credencial.user!.uid;
    } on FirebaseAuthException catch (erro) {
      throw ErroConta(mensagemDoAuth(erro));
    } on TimeoutException {
      throw const ErroConta('Sem conexão. Tente de novo com internet.');
    }

    final perfil = await _lerPerfil(uid);
    final local = await _porUid(uid);
    final db = await _banco.db;
    final nome =
        perfil?['nome'] as String? ?? local?.nome ?? _nomeDoEmail(email);
    final tipo =
        perfil?['tipo'] as String? ??
        local?.tipo.name ??
        TipoUsuario.aluno.name;
    final linha = {
      'uid_firebase': uid,
      'nome': nome,
      'email': email,
      'tipo': tipo == 'admin' ? 'admin' : 'aluno',
    };
    if (local != null) {
      await db.update('Usuario', linha, where: 'id = ?', whereArgs: [local.id]);
      return (usuario: await _porId(local.id), novo: false);
    }
    final id = await db.insert('Usuario', linha);
    return (usuario: await _porId(id), novo: true);
  }

  String _nomeDoEmail(String email) {
    final apelido = email.split('@').first;
    if (apelido.isEmpty) return 'Aluno';
    return apelido[0].toUpperCase() + apelido.substring(1);
  }

  /// Sai da conta e devolve um visitante novo.
  Future<Usuario> sair() async {
    await _auth?.signOut();
    return vincularVisitante(await criarVisitante());
  }
}

final usuarioRepositorioProvider = Provider<UsuarioRepositorio>(
  (ref) => UsuarioRepositorio(
    ref.watch(bancoProvider),
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);
