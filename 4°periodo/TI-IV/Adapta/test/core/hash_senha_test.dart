import 'package:adapta/core/seguranca/hash_senha.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('não armazena a senha em texto puro', () {
    final hash = HashSenha.gerar('segredo');
    expect(hash, isNot(contains('segredo')));
  });

  test('verifica senha correta e rejeita incorreta', () {
    final hash = HashSenha.gerar('segredo');
    expect(HashSenha.verificar('segredo', hash), isTrue);
    expect(HashSenha.verificar('outra', hash), isFalse);
  });

  test('salt diferente por chamada', () {
    expect(HashSenha.gerar('x'), isNot(HashSenha.gerar('x')));
  });
}
