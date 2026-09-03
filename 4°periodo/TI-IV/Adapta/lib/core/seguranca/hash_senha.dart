import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hash de senha com salt por usuário.
///
/// Formato armazenado em `Usuario.senha`: `<salt>$<sha256(salt + senha)>`.
/// Suficiente para o escopo acadêmico; trocar por bcrypt/argon2 se necessário.
class HashSenha {
  static final _random = Random.secure();

  static String gerar(String senha) {
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    return '$salt\$${_digest(salt, senha)}';
  }

  static bool verificar(String senha, String armazenado) {
    final partes = armazenado.split(r'$');
    if (partes.length != 2) return false;
    return _digest(partes[0], senha) == partes[1];
  }

  static String _digest(String salt, String senha) =>
      sha256.convert(utf8.encode('$salt$senha')).toString();
}
