import 'package:adapta/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Banco SQLite em memória com schema + seed, para testes de repositório.
Future<Database> bancoDeTeste({bool comSeed = true}) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  return abrirBanco(caminho: inMemoryDatabasePath, comSeed: comSeed);
}
