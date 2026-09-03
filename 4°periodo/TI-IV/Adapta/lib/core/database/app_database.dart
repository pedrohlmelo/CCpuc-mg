import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'seed.dart';
import 'tabelas.dart';

/// Versão do schema. Incrementar e tratar em `onUpgrade` quando o DDL mudar.
const int versaoBanco = 1;

/// Abre (ou cria) o banco local do Adapta.
///
/// - Em produção usa o diretório padrão do sqflite.
/// - Em testes passe [caminho] = `inMemoryDatabasePath` após configurar
///   `databaseFactory = databaseFactoryFfi`.
Future<Database> abrirBanco({String? caminho, bool comSeed = true}) async {
  final path = caminho ?? p.join(await getDatabasesPath(), 'adapta.db');
  return openDatabase(
    path,
    version: versaoBanco,
    onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, _) async {
      for (final ddl in tabelasDdl) {
        await db.execute(ddl);
      }
      if (comSeed) await inserirSeed(db);
    },
  );
}

/// Banco já aberto. É sobrescrito em `main.dart` (e nos testes) via
/// `ProviderScope(overrides: [databaseProvider.overrideWithValue(db)])`.
final databaseProvider = Provider<Database>(
  (_) => throw UnimplementedError(
    'databaseProvider precisa ser sobrescrito com um banco aberto.',
  ),
);
