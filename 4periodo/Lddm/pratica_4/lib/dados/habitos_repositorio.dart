import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../dominio/habito.dart';

class HabitosRepositorio {
  static const _iniciais = [
    Habito(nome: 'Beber água', meta: 'Meta: 8 copos por dia', icone: 'agua'),
    Habito(nome: 'Ler', meta: 'Meta: 20 páginas por dia', icone: 'leitura'),
    Habito(nome: 'Caminhar', meta: 'Meta: 30 minutos por dia', icone: 'caminhada'),
    Habito(nome: 'Dormir cedo', meta: 'Meta: antes das 23h', icone: 'sono'),
  ];

  Future<Database> _abrir() async => openDatabase(
    join(await getDatabasesPath(), 'habitos.db'),
    version: 1,
    onCreate: (db, _) async {
      await db.execute(
        'CREATE TABLE habitos('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'nome TEXT NOT NULL, '
        'meta TEXT NOT NULL, '
        'icone TEXT NOT NULL)',
      );
      for (final h in _iniciais) {
        await db.insert('habitos', h.toMap());
      }
    },
  );

  Future<List<Habito>> carregar() async {
    final db = await _abrir();
    final linhas = await db.query('habitos');
    return linhas.map(Habito.fromMap).toList();
  }

  Future<void> salvar(Habito h) async {
    final db = await _abrir();
    await db.insert('habitos', h.toMap());
  }

  Future<void> atualizar(Habito h) async {
    final db = await _abrir();
    await db.update('habitos', h.toMap(),
        where: 'id = ?', whereArgs: [h.id]);
  }

  Future<void> apagar(int id) async {
    final db = await _abrir();
    await db.delete('habitos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> arquivar(Habito h) async {
    await apagar(h.id!);
    await salvar(Habito(nome: h.nome, meta: h.meta, icone: h.icone));
  }
}
