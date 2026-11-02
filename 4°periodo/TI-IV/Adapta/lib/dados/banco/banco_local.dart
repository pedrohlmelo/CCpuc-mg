import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../preferencias.dart';
import 'seed.dart';

const _tabelas = [
  '''
CREATE TABLE Usuario (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid_firebase TEXT UNIQUE,
  nome TEXT NOT NULL,
  email TEXT,
  tipo TEXT NOT NULL DEFAULT 'aluno' CHECK (tipo IN ('aluno', 'admin'))
)''',
  '''
CREATE TABLE Materia (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL
)''',
  '''
CREATE TABLE Assunto (
  id INTEGER PRIMARY KEY,
  id_materia INTEGER NOT NULL REFERENCES Materia(id),
  nome TEXT NOT NULL,
  descricao TEXT NOT NULL DEFAULT ''
)''',
  '''
CREATE TABLE Grafo_Dependencia (
  id_prerequisito INTEGER NOT NULL REFERENCES Assunto(id),
  id_dependente INTEGER NOT NULL REFERENCES Assunto(id),
  peso REAL NOT NULL,
  PRIMARY KEY (id_prerequisito, id_dependente)
)''',
  '''
CREATE TABLE Questao (
  id INTEGER PRIMARY KEY,
  id_assunto INTEGER NOT NULL REFERENCES Assunto(id),
  enunciado TEXT NOT NULL,
  explicacao TEXT NOT NULL,
  dificuldade INTEGER NOT NULL CHECK (dificuldade BETWEEN 1 AND 3),
  dificuldade_calibrada REAL,
  imagem_url TEXT,
  imagem_local TEXT,
  imagem_descricao TEXT
)''',
  '''
CREATE TABLE Alternativa (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  id_questao INTEGER NOT NULL REFERENCES Questao(id),
  letra TEXT NOT NULL,
  texto TEXT,
  correta INTEGER NOT NULL,
  imagem_url TEXT,
  imagem_local TEXT,
  imagem_descricao TEXT,
  CHECK (texto IS NOT NULL OR imagem_url IS NOT NULL)
)''',
  '''
CREATE TABLE Historico_Estudo (
  id TEXT PRIMARY KEY,
  id_usuario INTEGER NOT NULL REFERENCES Usuario(id),
  id_questao INTEGER NOT NULL REFERENCES Questao(id),
  letra_escolhida TEXT NOT NULL,
  acertou INTEGER NOT NULL,
  data TEXT NOT NULL,
  tempo_gasto INTEGER NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0,
  atualizado_em TEXT NOT NULL
)''',
  '''
CREATE TABLE Nivel_Memoria (
  id_usuario INTEGER NOT NULL REFERENCES Usuario(id),
  id_assunto INTEGER NOT NULL REFERENCES Assunto(id),
  retencao_atual REAL NOT NULL,
  data_ultimo_estudo TEXT NOT NULL,
  qtd_revisoes INTEGER NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0,
  atualizado_em TEXT NOT NULL,
  PRIMARY KEY (id_usuario, id_assunto)
)''',
  '''
CREATE TABLE Proficiencia (
  id_usuario INTEGER NOT NULL REFERENCES Usuario(id),
  id_assunto INTEGER NOT NULL REFERENCES Assunto(id),
  nivel_estimado REAL NOT NULL,
  data_atualizacao TEXT NOT NULL,
  sincronizado INTEGER NOT NULL DEFAULT 0,
  atualizado_em TEXT NOT NULL,
  PRIMARY KEY (id_usuario, id_assunto)
)''',
  'CREATE INDEX idx_grafo_prerequisito ON Grafo_Dependencia(id_prerequisito)',
  'CREATE INDEX idx_grafo_dependente ON Grafo_Dependencia(id_dependente)',
];

/// Abre o `adapta.db`, a fonte de verdade do app no aparelho, e garante o
/// conteúdo inicial. A abertura é feita uma vez, no primeiro acesso.
class BancoLocal {
  static const nomeArquivo = 'adapta.db';
  static const versao = 1;

  /// Nos testes, a fábrica do `sqflite_common_ffi` e um banco em memória.
  final DatabaseFactory? fabrica;
  final String? caminho;
  final Preferencias preferencias;

  BancoLocal({
    this.fabrica,
    this.caminho,
    this.preferencias = const Preferencias(),
  });

  Future<Database>? _aberto;

  Future<Database> get db => _aberto ??= _abrir().catchError((Object erro) {
    _aberto = null;
    throw erro;
  });

  Future<Database> _abrir() async {
    final destino = caminho ?? join(await getDatabasesPath(), nomeArquivo);
    final banco = await (fabrica ?? databaseFactory).openDatabase(
      destino,
      options: OpenDatabaseOptions(
        version: versao,
        singleInstance: caminho == null,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          for (final comando in _tabelas) {
            await db.execute(comando);
          }
        },
      ),
    );
    await _garantirSeed(banco);
    return banco;
  }

  /// A preferência evita repetir o seed; a contagem cobre o caso de o banco
  /// ter sido apagado enquanto a preferência sobreviveu.
  Future<void> _garantirSeed(Database banco) async {
    final linhas = await banco.rawQuery('SELECT COUNT(*) AS n FROM Materia');
    final vazio = (linhas.first['n'] as int) == 0;
    if (!vazio && await preferencias.lerSeedConcluido()) return;
    if (vazio) {
      await banco.transaction((txn) async {
        final lote = txn.batch();
        gravarSeed((tabela, linha) => lote.insert(tabela, linha));
        await lote.commit(noResult: true);
      });
    }
    await preferencias.marcarSeedConcluido(versaoConteudoSeed);
  }

  Future<void> fechar() async {
    final aberto = _aberto;
    _aberto = null;
    await (await aberto)?.close();
  }
}

final bancoProvider = Provider<BancoLocal>((_) => BancoLocal());
