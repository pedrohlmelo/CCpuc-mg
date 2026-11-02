import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../banco/banco_local.dart';
import '../modelos.dart';

const nomeVisitante = 'Visitante';

class UsuarioRepositorio {
  final BancoLocal _banco;
  UsuarioRepositorio(this._banco);

  Usuario _usuario(Map<String, Object?> l) => Usuario(
    id: l['id'] as int,
    uidFirebase: l['uid_firebase'] as String?,
    nome: l['nome'] as String,
    email: l['email'] as String?,
    tipo: l['tipo'] == 'admin' ? TipoUsuario.admin : TipoUsuario.aluno,
  );

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

  /// Cria ou reencontra a conta local pelo e-mail.
  Future<Usuario> entrarLocal(
    String nome,
    String email,
    TipoUsuario tipo,
  ) async {
    final db = await _banco.db;
    final linhas = await db.query(
      'Usuario',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (linhas.isNotEmpty) return _usuario(linhas.first);
    final id = await db.insert('Usuario', {
      'nome': nome,
      'email': email,
      'tipo': tipo.name,
    });
    return Usuario(id: id, nome: nome, email: email, tipo: tipo);
  }

  Future<Usuario> criarOuObterVisitante() async =>
      await ultimoLocal() ?? await criarVisitante();
}

final usuarioRepositorioProvider = Provider<UsuarioRepositorio>(
  (ref) => UsuarioRepositorio(ref.watch(bancoProvider)),
);
