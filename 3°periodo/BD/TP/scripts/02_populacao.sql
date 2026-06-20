-- =====================================================================
-- Trabalho Pratico - Banco de Dados
-- Minimundo: Sistema de Doacoes da ONG "Somos do BHem" (Belo Horizonte/MG)
-- Script de POPULACAO do banco de dados
-- =====================================================================

-- ---------------------------- INSTITUICAO ----------------------------
INSERT INTO instituicao (id_instituicao, nome, cnpj, email, endereco, bairro, responsavel) VALUES
(1, 'Somos do BHem', '32.638.826/0001-77', 'contato@somosdobhem.org', 'Rua das Acacias, 120', 'Aaroes Reis', 'Mariana Lopes'),
(2, 'Lar Esperanca', '11.222.333/0001-44', 'contato@laresperanca.org', 'Rua Sao Joao, 540', 'Venda Nova', 'Roberto Dias'),
(3, 'Centro Comunitario Sao Vicente', '55.666.777/0001-88', 'svicente@email.com', 'Av. Vilarinho, 880', 'Floramar', 'Antonio Pereira');

-- ------------------------ TELEFONE_INSTITUICAO -----------------------
INSERT INTO telefone_instituicao (id_instituicao, telefone) VALUES
(1, '(31) 99185-6673'),
(1, '(31) 3491-1000'),
(2, '(31) 3411-2020'),
(3, '(31) 3422-7141'),
(3, '(31) 98777-0000');

-- ------------------------------ DOADOR -------------------------------
INSERT INTO doador (id_doador, nome, tipo_pessoa, cpf_cnpj, telefone, email, cidade, bairro) VALUES
(1, 'Carla Mendes Souza', 'F', '111.222.333-44', '(31) 98888-1010', 'carla@email.com', 'Belo Horizonte', 'Pampulha'),
(2, 'Joao Batista Ferreira', 'F', '222.333.444-55', '(31) 99777-2020', 'joao.b@email.com', 'Belo Horizonte', 'Santa Tereza'),
(3, 'Supermercado Bom Preco LTDA', 'J', '33.444.555/0001-66', '(31) 3333-3030', 'doacoes@bompreco.com', 'Belo Horizonte', 'Centro'),
(4, 'Padaria Pao Quente ME', 'J', '44.555.666/0001-77', '(31) 3344-4040', 'contato@paoquente.com', 'Belo Horizonte', 'Lagoinha'),
(5, 'Fernanda Oliveira Lima', 'F', '333.444.555-66', '(31) 98765-5050', 'fernanda@email.com', 'Contagem', 'Eldorado'),
(6, 'Igreja Comunidade da Paz', 'J', '55.666.777/0001-99', '(31) 3355-6060', 'paz@email.com', 'Belo Horizonte', 'Venda Nova'),
(7, 'Pedro Henrique Alves', 'F', '444.555.666-77', '(31) 99123-7070', 'pedro.h@email.com', 'Belo Horizonte', 'Cidade Nova'),
(8, 'Loja Veste Bem LTDA', 'J', '66.777.888/0001-11', '(31) 3366-8080', 'rh@vestebem.com', 'Belo Horizonte', 'Savassi');

-- ----------------------------- CATEGORIA -----------------------------
INSERT INTO categoria (id_categoria, nome, descricao, unidade_padrao) VALUES
(1, 'Alimento', 'Alimentos nao pereciveis', 'kg'),
(2, 'Roupa', 'Pecas de vestuario em bom estado', 'peca'),
(3, 'Cobertor', 'Cobertores e agasalhos', 'unidade'),
(4, 'Higiene', 'Produtos de higiene pessoal', 'unidade'),
(5, 'Limpeza', 'Produtos de limpeza domestica', 'unidade');

-- ---------------------------- VOLUNTARIO -----------------------------
INSERT INTO voluntario (id_voluntario, nome, cpf, telefone, funcao, data_ingresso, id_instituicao) VALUES
(1, 'Mariana Lopes',    '777.888.999-00', '(31) 98111-1111', 'Coordenadora', '2021-03-10', 1),
(2, 'Lucas Andrade',    '888.999.000-11', '(31) 98222-2222', 'Estoquista',   '2022-06-01', 1),
(3, 'Beatriz Carvalho', '999.000.111-22', '(31) 98333-3333', 'Atendente',    '2023-01-15', 1),
(4, 'Roberto Dias',     '000.111.222-33', '(31) 98444-4444', 'Coordenador',  '2020-09-05', 2),
(5, 'Antonio Pereira',  '123.123.123-12', '(31) 98555-5555', 'Coordenador',  '2019-11-20', 3);

-- ----------------------------- RECEPTOR ------------------------------
INSERT INTO receptor (id_receptor, primeiro_nome, sobrenome, cpf, data_nascimento, telefone, num_dependentes, bairro, situacao, id_instituicao) VALUES
(1, 'Maria das Gracas', 'Silva',    '321.321.321-32', '1985-04-12', '(31) 97000-0001', 3, 'Aaroes Reis', 'ATIVO', 1),
(2, 'Jose Carlos',      'Pereira',  '432.432.432-43', '1978-11-30', '(31) 97000-0002', 2, 'Floramar',    'ATIVO', 1),
(3, 'Ana Paula',        'Rodrigues','543.543.543-54', '1990-07-22', '(31) 97000-0003', 4, 'Venda Nova',  'ATIVO', 2),
(4, 'Sebastiao',        'Gomes',    '654.654.654-65', '1965-02-09', '(31) 97000-0004', 1, 'Lagoinha',    'ATIVO', 1),
(5, 'Rita de Cassia',   'Souza',    '765.765.765-76', '1982-09-17', '(31) 97000-0005', 2, 'Floramar',    'ATIVO', 3),
(6, 'Francisco',        'Antunes',  '876.876.876-87', '1971-12-03', '(31) 97000-0006', 0, 'Venda Nova',  'ATIVO', 2),
(7, 'Luzia Maria',      'Santos',   '987.987.987-98', '1995-05-25', '(31) 97000-0007', 3, 'Aaroes Reis', 'ATIVO', 1),
(8, 'Antonia',          'Ferreira', '147.147.147-14', '1988-08-08', '(31) 97000-0008', 5, 'Cidade Nova', 'ATIVO', 1);

-- ------------------------------ DOACAO -------------------------------
INSERT INTO doacao (id_doacao, data_doacao, observacao, id_doador, id_instituicao) VALUES
(1,  '2026-04-02', 'Campanha do agasalho',          1, 1),
(2,  '2026-04-05', 'Doacao mensal do supermercado', 3, 1),
(3,  '2026-04-10', 'Sobras de producao',            4, 1),
(4,  '2026-04-15', NULL,                             2, 1),
(5,  '2026-04-20', 'Arrecadacao da igreja',         6, 2),
(6,  '2026-05-02', 'Campanha de inverno',           8, 1),
(7,  '2026-05-08', 'Doacao individual',             5, 3),
(8,  '2026-05-12', NULL,                             7, 1),
(9,  '2026-05-18', 'Doacao mensal do supermercado', 3, 1),
(10, '2026-05-25', 'Itens de limpeza',              1, 2);

-- ---------------------------- ITEM_DOACAO ----------------------------
-- (id_doacao, numero) = chave; numero e a chave parcial da entidade fraca
INSERT INTO item_doacao (id_doacao, numero, descricao, quantidade, unidade, estado_conservacao, data_validade, id_categoria) VALUES
(1, 1, 'Cobertores de solteiro', 10, 'unidade', 'NOVO',      NULL,         3),
(1, 2, 'Casacos de frio adulto', 25, 'peca',    'USADO-BOM', NULL,         2),
(2, 1, 'Arroz tipo 1 5kg',       40, 'kg',      NULL,        '2027-01-30', 1),
(2, 2, 'Feijao carioca 1kg',     30, 'kg',      NULL,        '2026-12-15', 1),
(3, 1, 'Paes congelados',        20, 'kg',      NULL,        '2026-06-30', 1),
(4, 1, 'Calcas jeans infantil',  15, 'peca',    'USADO-BOM', NULL,         2),
(5, 1, 'Macarrao 500g',          50, 'unidade', NULL,        '2027-03-10', 1),
(6, 1, 'Cobertores casal',       12, 'unidade', 'NOVO',      NULL,         3),
(6, 2, 'Agasalhos infantis',     30, 'peca',    'NOVO',      NULL,         2),
(7, 1, 'Sabonetes',              60, 'unidade', NULL,        NULL,         4),
(7, 2, 'Cremes dentais',         40, 'unidade', NULL,        '2027-08-01', 4),
(8, 1, 'Camisetas adulto',       20, 'peca',    'USADO-BOM', NULL,         2),
(9, 1, 'Oleo de soja 900ml',     36, 'unidade', NULL,        '2027-02-20', 1),
(9, 2, 'Acucar 1kg',             24, 'kg',      NULL,        '2027-05-05', 1),
(10, 1, 'Detergente 500ml',      48, 'unidade', NULL,        NULL,         5),
(10, 2, 'Agua sanitaria 1L',     24, 'unidade', NULL,        NULL,         5);

-- ---------------------------- DISTRIBUICAO ---------------------------
INSERT INTO distribuicao (id_distribuicao, data_distribuicao, observacao, id_receptor, id_instituicao, id_voluntario) VALUES
(1, '2026-04-12', 'Cesta de inverno',   1, 1, 3),
(2, '2026-04-12', NULL,                  4, 1, 3),
(3, '2026-04-18', 'Atendimento mensal', 7, 1, 2),
(4, '2026-04-25', NULL,                  8, 1, 3),
(5, '2026-05-10', 'Doacao da igreja',   3, 2, 4),
(6, '2026-05-14', NULL,                  5, 3, 5),
(7, '2026-05-20', 'Cesta de limpeza',   2, 1, 2),
(8, '2026-05-28', 'Atendimento mensal', 1, 1, 3);

-- -------------------------- ITEM_DISTRIBUICAO ------------------------
-- (id_distribuicao, id_doacao, numero, quantidade)
INSERT INTO item_distribuicao (id_distribuicao, id_doacao, numero, quantidade) VALUES
(1, 1, 1, 2),
(1, 2, 1, 5),
(1, 2, 2, 4),
(2, 1, 2, 3),
(2, 3, 1, 5),
(3, 6, 1, 1),
(3, 9, 1, 4),
(4, 6, 2, 3),
(4, 7, 2, 2),
(5, 5, 1, 10),
(6, 7, 1, 5),
(6, 9, 2, 3),
(7, 10, 1, 4),
(7, 10, 2, 2),
(8, 1, 1, 1),
(8, 8, 1, 2);
