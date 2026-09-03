import 'package:adapta/features/autenticacao/data/usuario_repository.dart';
import 'package:adapta/features/autenticacao/domain/usuario.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_helpers.dart';

void main() {
  late Database db;
  late UsuarioRepository repo;

  setUp(() async {
    db = await bancoDeTeste();
    repo = UsuarioRepository(db);
  });
  tearDown(() => db.close());

  test('cadastra aluno e autentica (RF01)', () async {
    final u = await repo.cadastrar(
      nome: 'Ana',
      email: 'ANA@teste.com',
      senha: '123456',
    );
    expect(u.tipo, TipoUsuario.aluno);
    expect(u.email, 'ana@teste.com');

    final logado = await repo.autenticar('ana@teste.com', '123456');
    expect(logado?.id, u.id);
  });

  test('senha errada retorna null', () async {
    await repo.cadastrar(nome: 'Ana', email: 'ana@teste.com', senha: '123456');
    expect(await repo.autenticar('ana@teste.com', 'errada'), isNull);
  });

  test('e-mail duplicado lança EmailJaCadastrado', () async {
    await repo.cadastrar(nome: 'Ana', email: 'ana@teste.com', senha: '123456');
    await expectLater(
      () => repo.cadastrar(nome: 'Outra', email: 'ana@teste.com', senha: 'x'),
      throwsA(isA<EmailJaCadastrado>()),
    );
  });

  test('admin do seed autentica como admin', () async {
    final admin = await repo.autenticar('admin@adapta.app', 'admin123');
    expect(admin?.isAdmin, isTrue);
  });
}
