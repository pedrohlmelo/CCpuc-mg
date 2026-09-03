import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/usuario_repository.dart';
import '../domain/usuario.dart';

/// Usuário logado na sessão atual (`null` = deslogado).
class SessaoController extends Notifier<Usuario?> {
  @override
  Usuario? build() => null;

  /// Retorna `true` se autenticou.
  Future<bool> entrar(String email, String senha) async {
    final usuario = await ref
        .read(usuarioRepositoryProvider)
        .autenticar(email, senha);
    state = usuario;
    return usuario != null;
  }

  /// Cadastra e já entra. Lança [EmailJaCadastrado] se o e-mail existir.
  Future<void> cadastrar(String nome, String email, String senha) async {
    state = await ref
        .read(usuarioRepositoryProvider)
        .cadastrar(nome: nome, email: email, senha: senha);
  }

  void sair() => state = null;
}

final sessaoProvider = NotifierProvider<SessaoController, Usuario?>(
  SessaoController.new,
);
