-- =====================================================================
-- Trabalho Pratico - Banco de Dados
-- Minimundo: Sistema de Doacoes da ONG "Somos do BHem" (Belo Horizonte/MG)
-- Script de CRIACAO do banco de dados
-- =====================================================================

DROP TABLE IF EXISTS item_distribuicao;
DROP TABLE IF EXISTS distribuicao;
DROP TABLE IF EXISTS item_doacao;
DROP TABLE IF EXISTS doacao;
DROP TABLE IF EXISTS receptor;
DROP TABLE IF EXISTS voluntario;
DROP TABLE IF EXISTS categoria;
DROP TABLE IF EXISTS doador;
DROP TABLE IF EXISTS telefone_instituicao;
DROP TABLE IF EXISTS instituicao;

-- Instituicoes distribuidoras de doacoes
CREATE TABLE instituicao (
  id_instituicao INT PRIMARY KEY,
  nome           VARCHAR(120) NOT NULL,
  cnpj           VARCHAR(18),
  email          VARCHAR(120),
  endereco       VARCHAR(150),
  bairro         VARCHAR(60),
  responsavel    VARCHAR(120)
);

-- Telefones da instituicao (atributo multivalorado)
CREATE TABLE telefone_instituicao (
  id_instituicao INT,
  telefone       VARCHAR(20),
  PRIMARY KEY (id_instituicao, telefone),
  FOREIGN KEY (id_instituicao) REFERENCES instituicao(id_instituicao)
);

-- Doadores (pessoa fisica ou juridica)
CREATE TABLE doador (
  id_doador   INT PRIMARY KEY,
  nome        VARCHAR(120) NOT NULL,
  tipo_pessoa CHAR(1),
  cpf_cnpj    VARCHAR(18),
  telefone    VARCHAR(20),
  email       VARCHAR(120),
  cidade      VARCHAR(60),
  bairro      VARCHAR(60)
);

-- Categorias de objetos doados (alimento, roupa, cobertor, ...)
CREATE TABLE categoria (
  id_categoria   INT PRIMARY KEY,
  nome           VARCHAR(60) NOT NULL,
  descricao      VARCHAR(150),
  unidade_padrao VARCHAR(20)
);

-- Voluntarios que atuam em uma instituicao
CREATE TABLE voluntario (
  id_voluntario  INT PRIMARY KEY,
  nome           VARCHAR(120) NOT NULL,
  cpf            VARCHAR(14),
  telefone       VARCHAR(20),
  funcao         VARCHAR(60),
  data_ingresso  DATE,
  id_instituicao INT REFERENCES instituicao(id_instituicao)
);

-- Receptores (pessoas necessitadas atendidas por uma instituicao)
-- nome composto (primeiro_nome + sobrenome); idade e derivada (nao armazenada)
CREATE TABLE receptor (
  id_receptor     INT PRIMARY KEY,
  primeiro_nome   VARCHAR(60) NOT NULL,
  sobrenome       VARCHAR(80) NOT NULL,
  cpf             VARCHAR(14),
  data_nascimento DATE,
  telefone        VARCHAR(20),
  num_dependentes INT,
  bairro          VARCHAR(60),
  situacao        VARCHAR(20),
  id_instituicao  INT REFERENCES instituicao(id_instituicao)
);

-- Doacoes feitas por um doador para uma instituicao
CREATE TABLE doacao (
  id_doacao      INT PRIMARY KEY,
  data_doacao    DATE,
  observacao     VARCHAR(200),
  id_doador      INT REFERENCES doador(id_doador),
  id_instituicao INT REFERENCES instituicao(id_instituicao)
);

-- Itens de cada doacao (ENTIDADE FRACA de doacao; chave parcial = numero)
CREATE TABLE item_doacao (
  id_doacao          INT,
  numero             INT,
  descricao          VARCHAR(120) NOT NULL,
  quantidade         DECIMAL(10,2),
  unidade            VARCHAR(20),
  estado_conservacao VARCHAR(20),
  data_validade      DATE,
  id_categoria       INT REFERENCES categoria(id_categoria),
  PRIMARY KEY (id_doacao, numero),
  FOREIGN KEY (id_doacao) REFERENCES doacao(id_doacao)
);

-- Distribuicoes: entrega das doacoes a um receptor (recepcao pelo receptor)
CREATE TABLE distribuicao (
  id_distribuicao   INT PRIMARY KEY,
  data_distribuicao DATE,
  observacao        VARCHAR(200),
  id_receptor       INT REFERENCES receptor(id_receptor),
  id_instituicao    INT REFERENCES instituicao(id_instituicao),
  id_voluntario     INT REFERENCES voluntario(id_voluntario)
);

-- Itens entregues em cada distribuicao (associacao N:N com quantidade)
CREATE TABLE item_distribuicao (
  id_distribuicao INT,
  id_doacao       INT,
  numero          INT,
  quantidade      DECIMAL(10,2),
  PRIMARY KEY (id_distribuicao, id_doacao, numero),
  FOREIGN KEY (id_distribuicao) REFERENCES distribuicao(id_distribuicao),
  FOREIGN KEY (id_doacao, numero) REFERENCES item_doacao(id_doacao, numero)
);
