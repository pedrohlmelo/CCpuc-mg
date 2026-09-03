import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/seguranca/hash_senha.dart';
import '../domain/usuario.dart';

class EmailJaCadastrado implements Exception {
  @override
  String toString() => 'E-mail já cadastrado.';
}

/// RF01 — cadastro e autenticação.
class UsuarioRepository {
  final Database _db;
  UsuarioRepository(this._db);

  Future<Usuario> cadastrar({
    required String nome,
    required String email,
    required String senha,
    TipoUsuario tipo = TipoUsuario.aluno,
  }) async {
    final emailNorm = email.trim().toLowerCase();
    final existe = await _db.query(
      'Usuario',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [emailNorm],
    );
    if (existe.isNotEmpty) throw EmailJaCadastrado();

    final id = await _db.insert('Usuario', {
      'nome': nome.trim(),
      'email': emailNorm,
      'senha': HashSenha.gerar(senha),
      'tipo': tipo.name,
    });
    return Usuario(id: id, nome: nome.trim(), email: emailNorm, tipo: tipo);
  }

  /// Retorna o usuário se e-mail e senha conferem; senão `null`.
  Future<Usuario?> autenticar(String email, String senha) async {
    final linhas = await _db.query(
      'Usuario',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    final linha = linhas.first;
    if (!HashSenha.verificar(senha, linha['senha'] as String)) return null;
    return Usuario.deMapa(linha);
  }

  Future<Usuario?> buscarPorId(int id) async {
    final linhas = await _db.query(
      'Usuario',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return linhas.isEmpty ? null : Usuario.deMapa(linhas.first);
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepository>(
  (ref) => UsuarioRepository(ref.watch(databaseProvider)),
);
