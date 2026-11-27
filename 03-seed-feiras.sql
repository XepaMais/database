-- =====================================================================
-- Xepa+ | 03-seed-feiras.sql
-- Feiras livres reais de São Paulo usadas no mapa e no cadastro do feirante.
--
-- Fonte: endereços reais levantados pela equipe para o piloto (Freguesia do Ó,
-- Brasilândia e Pirituba) e feiras da Zona Oeste; coordenadas do Google Maps.
-- Referência para ampliar: Relação Oficial de Feiras Livres da Prefeitura de SP
-- (dados.prefeitura.sp.gov.br, conjunto "relacao-de-feiras-livres").
-- Dias da semana: 1 = segunda ... 7 = domingo.
--
-- Só adiciona o que falta (confere pelo nome): pode rodar de novo sem duplicar.
-- Para ampliar a lista, veja "Atualização das feiras" no README.md.
-- =====================================================================
USE db_xepa;

-- Brasilândia
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira da Vila Brasilândia', 'Rua Maria Nazaro da Silva', '224', '02809030', 'São Paulo', 'SP', '07:00', '13:00', -23.471943, -46.705273
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira da Vila Brasilândia');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 6 AS dia) d WHERE nome_feira = 'Feira da Vila Brasilândia';

-- Brasilândia
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira da Rua Laranjeiras do Sul', 'Rua Laranjeiras do Sul', 's/n', '02812050', 'São Paulo', 'SP', '07:00', '12:30', -23.459979, -46.717795
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira da Rua Laranjeiras do Sul');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 3 AS dia) d WHERE nome_feira = 'Feira da Rua Laranjeiras do Sul';

-- Freguesia do Ó
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira da Freguesia do Ó - Bruno Bertucci', 'Rua Bruno Bertucci', '200', '02910055', 'São Paulo', 'SP', '07:00', '13:00', -23.503534, -46.700059
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira da Freguesia do Ó - Bruno Bertucci');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 5 AS dia) d WHERE nome_feira = 'Feira da Freguesia do Ó - Bruno Bertucci';

-- Freguesia do Ó
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira da Freguesia do Ó - Chico de Paula', 'Rua Chico de Paula', 's/n', '02926000', 'São Paulo', 'SP', '07:00', '12:30', -23.499204, -46.698580
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira da Freguesia do Ó - Chico de Paula');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 2 AS dia) d WHERE nome_feira = 'Feira da Freguesia do Ó - Chico de Paula';

-- Pirituba
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira de Pirituba - Rua Jurubim', 'Rua Jurubim', '10', '05159200', 'São Paulo', 'SP', '06:30', '13:00', -23.484007, -46.751394
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira de Pirituba - Rua Jurubim');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 6 AS dia) d WHERE nome_feira = 'Feira de Pirituba - Rua Jurubim';

-- Pirituba
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira de Pirituba - Av. do Anastácio', 'Avenida do Anastácio', 's/n', '05138100', 'São Paulo', 'SP', '07:00', '13:30', -23.486551, -46.738090
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira de Pirituba - Av. do Anastácio');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 7 AS dia) d WHERE nome_feira = 'Feira de Pirituba - Av. do Anastácio';

-- Lapa
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira Livre da Lapa', 'Rua Guaicurus', 's/n', '05033000', 'São Paulo', 'SP', '07:00', '13:00', -23.522800, -46.701200
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira Livre da Lapa');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 2 AS dia UNION ALL SELECT 3 AS dia UNION ALL SELECT 4 AS dia UNION ALL SELECT 5 AS dia UNION ALL SELECT 6 AS dia UNION ALL SELECT 7 AS dia) d WHERE nome_feira = 'Feira Livre da Lapa';

-- Pinheiros
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira de Pinheiros', 'Rua Cardeal Arcoverde', 's/n', '05407001', 'São Paulo', 'SP', '06:00', '14:00', -23.559400, -46.685600
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira de Pinheiros');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 3 AS dia UNION ALL SELECT 6 AS dia) d WHERE nome_feira = 'Feira de Pinheiros';

-- Água Branca
INSERT INTO tb_feira (nome_feira, endereco_feira, numero_feira, cep_feira, cidade_feira, uf_feira, horario_inicio, horario_fim, latitude, longitude)
SELECT 'Feira Xepa Central', 'Rua Clélia', 's/n', '05042000', 'São Paulo', 'SP', '08:00', '17:00', -23.528086, -46.691760
WHERE NOT EXISTS (SELECT 1 FROM tb_feira WHERE nome_feira = 'Feira Xepa Central');
INSERT IGNORE INTO tb_feira_dia (id_feira, dia_semana)
SELECT id_feira, d.dia FROM tb_feira JOIN (SELECT 1 AS dia UNION ALL SELECT 2 AS dia UNION ALL SELECT 3 AS dia UNION ALL SELECT 4 AS dia UNION ALL SELECT 5 AS dia UNION ALL SELECT 6 AS dia UNION ALL SELECT 7 AS dia) d WHERE nome_feira = 'Feira Xepa Central';
