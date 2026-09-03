/// DDL das tabelas do Adapta.
///
/// Espelha a seção 9 de `docs/memoria.md`. Nomes em português sem acento.
/// A ordem importa: tabelas referenciadas vêm antes das que referenciam.
const List<String> tabelasDdl = [
  '''
  CREATE TABLE Usuario (
    id     INTEGER PRIMARY KEY AUTOINCREMENT,
    nome   TEXT    NOT NULL,
    email  TEXT    NOT NULL UNIQUE,
    senha  TEXT    NOT NULL,            -- hash, nunca texto puro
    tipo   TEXT    NOT NULL DEFAULT 'aluno'  -- 'aluno' | 'admin'
  )''',
  '''
  CREATE TABLE Materia (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    nome TEXT    NOT NULL UNIQUE
  )''',
  '''
  CREATE TABLE Assunto (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    id_materia INTEGER NOT NULL REFERENCES Materia(id) ON DELETE CASCADE,
    nome       TEXT    NOT NULL,
    descricao  TEXT
  )''',
  '''
  CREATE TABLE Grafo_Dependencia (
    id_prerequisito INTEGER NOT NULL REFERENCES Assunto(id) ON DELETE CASCADE,
    id_dependente   INTEGER NOT NULL REFERENCES Assunto(id) ON DELETE CASCADE,
    peso            REAL    NOT NULL DEFAULT 1.0,
    PRIMARY KEY (id_prerequisito, id_dependente)
  )''',
  'CREATE INDEX idx_grafo_prerequisito ON Grafo_Dependencia(id_prerequisito)',
  'CREATE INDEX idx_grafo_dependente ON Grafo_Dependencia(id_dependente)',
  '''
  CREATE TABLE Questao (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    id_assunto  INTEGER NOT NULL REFERENCES Assunto(id) ON DELETE CASCADE,
    enunciado   TEXT    NOT NULL,
    explicacao  TEXT,
    dificuldade INTEGER NOT NULL DEFAULT 1   -- 1 (fácil) .. 5 (difícil), declarada pelo autor
  )''',
  '''
  CREATE TABLE Alternativa (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    id_questao INTEGER NOT NULL REFERENCES Questao(id) ON DELETE CASCADE,
    letra      TEXT    NOT NULL,
    texto      TEXT    NOT NULL,
    correta    INTEGER NOT NULL DEFAULT 0,
    UNIQUE (id_questao, letra)
  )''',
  '''
  CREATE TABLE Historico_Estudo (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    id_usuario  INTEGER NOT NULL REFERENCES Usuario(id) ON DELETE CASCADE,
    id_questao  INTEGER NOT NULL REFERENCES Questao(id) ON DELETE CASCADE,
    acertou     INTEGER NOT NULL,
    data        TEXT    NOT NULL,           -- ISO-8601
    tempo_gasto INTEGER NOT NULL DEFAULT 0  -- segundos
  )''',
  'CREATE INDEX idx_historico_usuario ON Historico_Estudo(id_usuario)',
  '''
  CREATE TABLE Nivel_Memoria (
    id_usuario         INTEGER NOT NULL REFERENCES Usuario(id) ON DELETE CASCADE,
    id_assunto         INTEGER NOT NULL REFERENCES Assunto(id) ON DELETE CASCADE,
    retencao_atual     REAL    NOT NULL DEFAULT 1.0,  -- 0.0 .. 1.0
    data_ultimo_estudo TEXT    NOT NULL,
    qtd_revisoes       INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (id_usuario, id_assunto)
  )''',
  '''
  CREATE TABLE Proficiencia (
    id_usuario       INTEGER NOT NULL REFERENCES Usuario(id) ON DELETE CASCADE,
    id_assunto       INTEGER NOT NULL REFERENCES Assunto(id) ON DELETE CASCADE,
    nivel_estimado   REAL    NOT NULL DEFAULT 0.0,
    data_atualizacao TEXT    NOT NULL,
    PRIMARY KEY (id_usuario, id_assunto)
  )''',
];
