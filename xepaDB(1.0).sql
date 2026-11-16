CREATE DATABASE IF NOT EXISTS db_xepa
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE db_xepa;

CREATE TABLE tb_conta (
    id_conta        INT AUTO_INCREMENT PRIMARY KEY,
    nome_conta      VARCHAR(100) NOT NULL,
    cpf_conta       CHAR(11)     NOT NULL,             
    email_conta     VARCHAR(100) NOT NULL,
    senha_conta     VARCHAR(255) NOT NULL,              -- hash BCrypt, nunca a senha pura
    telefone_conta  VARCHAR(20),
    ativo           BOOLEAN      NOT NULL DEFAULT TRUE, -- soft delete
    data_cadastro   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_conta_cpf   UNIQUE (cpf_conta),
    CONSTRAINT uk_conta_email UNIQUE (email_conta)
);

-- Uma conta pode ser consumidor E feirante, mas no máximo um de cada (UNIQUE)
CREATE TABLE tb_consumidor (
    id_consumidor INT AUTO_INCREMENT PRIMARY KEY,
    id_conta      INT NOT NULL,
    CONSTRAINT uk_consumidor_conta UNIQUE (id_conta),
    CONSTRAINT fk_consumidor_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta)
);

CREATE TABLE tb_colaborador (
    id_colaborador INT AUTO_INCREMENT PRIMARY KEY,
    id_conta       INT NOT NULL,
    CONSTRAINT uk_colaborador_conta UNIQUE (id_conta),
    CONSTRAINT fk_colaborador_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta)
);

CREATE TABLE tb_plano (
    id_plano        INT AUTO_INCREMENT PRIMARY KEY,
    id_colaborador  INT           NOT NULL,             -- colaborador que cadastrou o plano
    nome_plano      VARCHAR(60)   NOT NULL,
    descricao_plano TEXT,
    valor_plano     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    percentual_comissao DECIMAL(5,2) NOT NULL DEFAULT 0.00, -- taxa do Xepa+ sobre cada venda (ex.: 15.00 = 15%)
    ativo           BOOLEAN       NOT NULL DEFAULT TRUE,
    CONSTRAINT uk_plano_nome  UNIQUE (nome_plano),
    CONSTRAINT ck_plano_valor CHECK (valor_plano >= 0),
    CONSTRAINT ck_plano_comissao CHECK (percentual_comissao BETWEEN 0 AND 100),
    CONSTRAINT fk_plano_colaborador FOREIGN KEY (id_colaborador) REFERENCES tb_colaborador(id_colaborador)
);

CREATE TABLE tb_feirante (
    id_feirante        INT AUTO_INCREMENT PRIMARY KEY,
    id_conta           INT          NOT NULL,
    id_plano           INT,
    nome_fantasia      VARCHAR(100) NOT NULL,
    cnpj_feirante      CHAR(14),                        -- só dígitos; NULL permitido (vários NULLs não violam UNIQUE)
    ccm_feirante       VARCHAR(20),
    matricula_feirante VARCHAR(20),
    grupo_comercio     VARCHAR(60),
    CONSTRAINT uk_feirante_conta     UNIQUE (id_conta),
    CONSTRAINT uk_feirante_cnpj      UNIQUE (cnpj_feirante),
    CONSTRAINT uk_feirante_matricula UNIQUE (matricula_feirante),
    CONSTRAINT fk_feirante_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta),
    CONSTRAINT fk_feirante_plano FOREIGN KEY (id_plano) REFERENCES tb_plano(id_plano)
);

-- Guarda o HASH do refresh token, não o token em si
CREATE TABLE tb_dispositivo_sessao (
    id_dispositivo INT AUTO_INCREMENT PRIMARY KEY,
    id_conta       INT      NOT NULL,
    nome_aparelho  VARCHAR(100),
    token_hash     CHAR(64) NOT NULL,                   -- SHA-256 em hexadecimal
    data_criacao   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira_em      DATETIME NOT NULL,
    ultimo_acesso  DATETIME,
    revogado       BOOLEAN  NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_dispositivo_token UNIQUE (token_hash),
    CONSTRAINT fk_dispositivo_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta) ON DELETE CASCADE
);

CREATE TABLE tb_chat (
    id_chat       INT AUTO_INCREMENT PRIMARY KEY,
    id_consumidor INT      NOT NULL,
    id_feirante   INT      NOT NULL,
    data_inicio   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_chat_par UNIQUE (id_consumidor, id_feirante),   -- um chat por par
    CONSTRAINT fk_chat_consumidor FOREIGN KEY (id_consumidor) REFERENCES tb_consumidor(id_consumidor),
    CONSTRAINT fk_chat_feirante   FOREIGN KEY (id_feirante)   REFERENCES tb_feirante(id_feirante)
);

CREATE TABLE tb_mensagem (
    id_mensagem    INT AUTO_INCREMENT PRIMARY KEY,
    id_chat        INT      NOT NULL,
    id_conta       INT      NOT NULL,                   -- remetente (validar no backend que pertence ao chat)
    texto_mensagem TEXT     NOT NULL,
    data_envio     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    lida           BOOLEAN  NOT NULL DEFAULT FALSE,
    INDEX idx_mensagem_chat_data (id_chat, data_envio),
    CONSTRAINT fk_mensagem_chat  FOREIGN KEY (id_chat)  REFERENCES tb_chat(id_chat) ON DELETE CASCADE,
    CONSTRAINT fk_mensagem_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta)
);

CREATE TABLE tb_mensagem_ia (
    id_mensagem_ia    INT AUTO_INCREMENT PRIMARY KEY,
    id_conta          INT         NOT NULL,
    papel             VARCHAR(10) NOT NULL,             -- quem escreveu: USUARIO ou IA
    texto_mensagem_ia TEXT        NOT NULL,
    data_envio        DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_mensagem_ia_conta_data (id_conta, data_envio),
    CONSTRAINT ck_mensagem_ia_papel CHECK (papel IN ('USUARIO', 'IA')),
    CONSTRAINT fk_mensagem_ia_conta FOREIGN KEY (id_conta) REFERENCES tb_conta(id_conta) ON DELETE CASCADE
);

CREATE TABLE tb_feira (
    id_feira       INT AUTO_INCREMENT PRIMARY KEY,
    nome_feira     VARCHAR(100) NOT NULL,
    endereco_feira VARCHAR(150) NOT NULL,
    cep_feira      CHAR(8),                             -- só dígitos
    cidade_feira   VARCHAR(80)  NOT NULL,
    uf_feira       CHAR(2)      NOT NULL,
    dia_semana     TINYINT      NOT NULL,               -- 1=segunda ... 7=domingo (igual ao DayOfWeek do Java)
    horario_inicio TIME,
    horario_fim    TIME,
    latitude       DECIMAL(9,6),                        -- opcional: para mapa / "feiras perto de mim"
    longitude      DECIMAL(9,6),
    INDEX idx_feira_cidade (uf_feira, cidade_feira),
    CONSTRAINT ck_feira_dia     CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_feira_horario CHECK (horario_fim > horario_inicio)
);

-- Quais feirantes trabalham em quais feiras (@ManyToMany + @JoinTable no JPA)
CREATE TABLE tb_feirante_feira (
    id_feirante INT NOT NULL,
    id_feira    INT NOT NULL,
    PRIMARY KEY (id_feirante, id_feira),
    CONSTRAINT fk_ff_feirante FOREIGN KEY (id_feirante) REFERENCES tb_feirante(id_feirante) ON DELETE CASCADE,
    CONSTRAINT fk_ff_feira    FOREIGN KEY (id_feira)    REFERENCES tb_feira(id_feira)       ON DELETE CASCADE
);

CREATE TABLE tb_categoria (
    id_categoria   INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria VARCHAR(60) NOT NULL,
    CONSTRAINT uk_categoria_nome UNIQUE (nome_categoria)
);

CREATE TABLE tb_produto (
    id_produto        INT AUTO_INCREMENT PRIMARY KEY,
    id_feirante       INT          NOT NULL,
    id_categoria      INT          NOT NULL,
    nome_produto      VARCHAR(100) NOT NULL,
    descricao_produto TEXT,
    imagem_produto    VARCHAR(255),
    unidade_medida    VARCHAR(10)  NOT NULL,            -- em que unidade a quantidade é medida
    preco_referencia  DECIMAL(10,2),
    ativo             BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_produto_unidade CHECK (unidade_medida IN ('KG', 'UNIDADE', 'MACO', 'DUZIA', 'BANDEJA')),
    CONSTRAINT ck_produto_preco   CHECK (preco_referencia >= 0),
    CONSTRAINT fk_produto_feirante  FOREIGN KEY (id_feirante)  REFERENCES tb_feirante(id_feirante),
    CONSTRAINT fk_produto_categoria FOREIGN KEY (id_categoria) REFERENCES tb_categoria(id_categoria)
);

-- Regra para o backend: o feirante dono do produto precisa estar em tb_feirante_feira para essa feira
CREATE TABLE tb_xepa (
    id_xepa                 INT AUTO_INCREMENT PRIMARY KEY,
    id_produto              INT           NOT NULL,
    id_feira                INT           NOT NULL,
    quantidade_xepa         DECIMAL(10,2) NOT NULL,     -- quantidade disponível, na unidade do produto
    preco_xepa              DECIMAL(10,2) NOT NULL,
    validade_xepa           DATE,
    data_retirada           DATE          NOT NULL,
    horario_retirada_inicio TIME          NOT NULL,
    horario_retirada_fim    TIME          NOT NULL,
    status_xepa             VARCHAR(20)   NOT NULL DEFAULT 'DISPONIVEL',
    data_cadastro           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    versao                  INT           NOT NULL DEFAULT 0,   -- @Version (evita vender a mesma xepa duas vezes)
    INDEX idx_xepa_busca (id_feira, status_xepa, data_retirada),
    CONSTRAINT ck_xepa_quantidade CHECK (quantidade_xepa >= 0),
    CONSTRAINT ck_xepa_preco      CHECK (preco_xepa > 0),
    CONSTRAINT ck_xepa_horario    CHECK (horario_retirada_fim > horario_retirada_inicio),
    CONSTRAINT ck_xepa_status     CHECK (status_xepa IN ('DISPONIVEL', 'ESGOTADA', 'EXPIRADA', 'CANCELADA')),
    CONSTRAINT fk_xepa_produto FOREIGN KEY (id_produto) REFERENCES tb_produto(id_produto),
    CONSTRAINT fk_xepa_feira   FOREIGN KEY (id_feira)   REFERENCES tb_feira(id_feira)
);

-- Um carrinho por consumidor (esvaziado após o checkout)
CREATE TABLE tb_carrinho (
    id_carrinho   INT AUTO_INCREMENT PRIMARY KEY,
    id_consumidor INT      NOT NULL,
    data_criacao  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_carrinho_consumidor UNIQUE (id_consumidor),
    CONSTRAINT fk_carrinho_consumidor FOREIGN KEY (id_consumidor) REFERENCES tb_consumidor(id_consumidor) ON DELETE CASCADE
);

CREATE TABLE tb_item_carrinho (
    id_item_carrinho INT AUTO_INCREMENT PRIMARY KEY,
    id_carrinho      INT           NOT NULL,
    id_xepa          INT           NOT NULL,
    quantidade_item  DECIMAL(10,2) NOT NULL,
    CONSTRAINT uk_item_carrinho   UNIQUE (id_carrinho, id_xepa),   -- mesma xepa = soma a quantidade
    CONSTRAINT ck_item_carrinho_qtd CHECK (quantidade_item > 0),
    CONSTRAINT fk_item_carrinho_carrinho FOREIGN KEY (id_carrinho) REFERENCES tb_carrinho(id_carrinho) ON DELETE CASCADE,
    CONSTRAINT fk_item_carrinho_xepa     FOREIGN KEY (id_xepa)     REFERENCES tb_xepa(id_xepa)         ON DELETE CASCADE
);

-- No checkout, o carrinho é dividido em UM pedido POR FEIRANTE
CREATE TABLE tb_pedido (
    id_pedido       INT AUTO_INCREMENT PRIMARY KEY,
    id_consumidor   INT           NOT NULL,
    id_feirante     INT           NOT NULL,
    data_pedido     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status_pedido   VARCHAR(30)   NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
    valor_total     DECIMAL(10,2) NOT NULL,             -- "foto" do total no momento da compra
    percentual_comissao DECIMAL(5,2)  NOT NULL DEFAULT 0.00, -- "foto" da comissão do plano do feirante na compra
    valor_comissao      DECIMAL(10,2) NOT NULL DEFAULT 0.00, -- valor_total * percentual / 100, arredondado em centavos
    codigo_retirada CHAR(6),                            -- código mostrado ao feirante na retirada
    INDEX idx_pedido_feirante_status (id_feirante, status_pedido),
    CONSTRAINT ck_pedido_valor  CHECK (valor_total >= 0),
    CONSTRAINT ck_pedido_comissao CHECK (percentual_comissao BETWEEN 0 AND 100
        AND valor_comissao BETWEEN 0 AND valor_total),
    CONSTRAINT ck_pedido_status CHECK (status_pedido IN
        ('AGUARDANDO_PAGAMENTO', 'PAGO', 'PRONTO_RETIRADA', 'RETIRADO', 'CANCELADO')),
    CONSTRAINT fk_pedido_consumidor FOREIGN KEY (id_consumidor) REFERENCES tb_consumidor(id_consumidor),
    CONSTRAINT fk_pedido_feirante   FOREIGN KEY (id_feirante)   REFERENCES tb_feirante(id_feirante)
);

CREATE TABLE tb_item_pedido (
    id_item_pedido  INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido       INT           NOT NULL,
    id_xepa         INT           NOT NULL,
    quantidade_item DECIMAL(10,2) NOT NULL,
    preco_unitario  DECIMAL(10,2) NOT NULL,             -- preço congelado no momento da compra
    CONSTRAINT uk_item_pedido     UNIQUE (id_pedido, id_xepa),
    CONSTRAINT ck_item_pedido_qtd   CHECK (quantidade_item > 0),
    CONSTRAINT ck_item_pedido_preco CHECK (preco_unitario >= 0),
    CONSTRAINT fk_item_pedido_pedido FOREIGN KEY (id_pedido) REFERENCES tb_pedido(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_item_pedido_xepa   FOREIGN KEY (id_xepa)   REFERENCES tb_xepa(id_xepa)
);

CREATE TABLE tb_tipo_pagamento (
    id_tipo_pagamento INT AUTO_INCREMENT PRIMARY KEY,
    metodo_pagamento  VARCHAR(40) NOT NULL,
    CONSTRAINT uk_tipo_pagamento UNIQUE (metodo_pagamento)
);

-- Um pedido pode ter várias tentativas de pagamento
CREATE TABLE tb_pagamento (
    id_pagamento         INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido            INT           NOT NULL,
    id_tipo_pagamento    INT           NOT NULL,
    valor_pagamento      DECIMAL(10,2) NOT NULL,
    status_pagamento     VARCHAR(20)   NOT NULL DEFAULT 'PENDENTE',
    id_transacao_gateway VARCHAR(100),                  -- ID retornado pelo Mercado Pago / Pix etc.
    data_criacao         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_pagamento       DATETIME,                      -- preenchida quando aprovado
    CONSTRAINT ck_pagamento_valor  CHECK (valor_pagamento > 0),
    CONSTRAINT ck_pagamento_status CHECK (status_pagamento IN ('PENDENTE', 'APROVADO', 'RECUSADO', 'ESTORNADO')),
    CONSTRAINT fk_pagamento_pedido FOREIGN KEY (id_pedido)         REFERENCES tb_pedido(id_pedido),
    CONSTRAINT fk_pagamento_tipo   FOREIGN KEY (id_tipo_pagamento) REFERENCES tb_tipo_pagamento(id_tipo_pagamento)
);


CREATE TABLE tb_avaliacao (
    id_avaliacao   INT AUTO_INCREMENT PRIMARY KEY,
    id_pedido      INT      NOT NULL,
    id_consumidor  INT      NOT NULL,                   -- devem bater com o pedido (validar no backend)
    id_feirante    INT      NOT NULL,
    nota           TINYINT  NOT NULL,
    comentario     TEXT,
    data_avaliacao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_avaliacao_pedido UNIQUE (id_pedido),
    CONSTRAINT ck_avaliacao_nota   CHECK (nota BETWEEN 1 AND 5),
    CONSTRAINT fk_avaliacao_pedido     FOREIGN KEY (id_pedido)     REFERENCES tb_pedido(id_pedido),
    CONSTRAINT fk_avaliacao_consumidor FOREIGN KEY (id_consumidor) REFERENCES tb_consumidor(id_consumidor),
    CONSTRAINT fk_avaliacao_feirante   FOREIGN KEY (id_feirante)   REFERENCES tb_feirante(id_feirante)
);

CREATE TABLE tb_receita_culinaria (
    id_receita     INT AUTO_INCREMENT PRIMARY KEY,
    titulo_receita VARCHAR(120) NOT NULL,
    imagem_receita VARCHAR(255),
    modo_preparo   TEXT,
    tempo_preparo  INT,                                 -- em minutos
    CONSTRAINT ck_receita_tempo CHECK (tempo_preparo > 0)
);

CREATE TABLE tb_ingrediente_receita (
    id_ingrediente         INT AUTO_INCREMENT PRIMARY KEY,
    id_receita             INT          NOT NULL,
    id_categoria           INT,                         -- opcional: liga o ingrediente às xepas da categoria
    nome_ingrediente       VARCHAR(100) NOT NULL,
    quantidade_ingrediente VARCHAR(50),                 -- texto livre: "2 xícaras", "a gosto"
    CONSTRAINT fk_ingrediente_receita   FOREIGN KEY (id_receita)   REFERENCES tb_receita_culinaria(id_receita) ON DELETE CASCADE,
    CONSTRAINT fk_ingrediente_categoria FOREIGN KEY (id_categoria) REFERENCES tb_categoria(id_categoria)
);

-- ==================== FINANCEIRO DO FEIRANTE ====================
-- Lucros (rendas), despesas e saques. Quando um pedido é pago, o backend grava, na mesma transação:
--   1) tb_renda    com o valor líquido (valor_total - valor_comissao), ligada ao pedido;
--   2) tb_despesa  com a comissão do Xepa+ (categoria 'Taxa do Xepa+'), ligada ao mesmo pedido.
-- O UNIQUE em id_pedido impede lançar a mesma venda (ou a mesma taxa) duas vezes.

CREATE TABLE tb_origem_renda (
    id_origem_renda   INT AUTO_INCREMENT PRIMARY KEY,
    nome_origem_renda VARCHAR(60) NOT NULL,
    CONSTRAINT uk_origem_renda_nome UNIQUE (nome_origem_renda)
);

CREATE TABLE tb_renda (
    id_renda        INT AUTO_INCREMENT PRIMARY KEY,
    id_feirante     INT           NOT NULL,
    id_origem_renda INT           NOT NULL,
    id_pedido       INT,                                -- preenchido só nas vendas pelo app (renda automática)
    id_feira        INT,                                -- opcional: feira onde a renda aconteceu
    descricao_renda VARCHAR(150)  NOT NULL,
    valor_renda     DECIMAL(10,2) NOT NULL,             -- valor que fica com o feirante (já sem a comissão)
    data_renda      DATE          NOT NULL,
    data_cadastro   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_renda_feirante_data (id_feirante, data_renda),
    CONSTRAINT uk_renda_pedido UNIQUE (id_pedido),
    CONSTRAINT ck_renda_valor  CHECK (valor_renda > 0),
    CONSTRAINT fk_renda_feirante FOREIGN KEY (id_feirante)     REFERENCES tb_feirante(id_feirante),
    CONSTRAINT fk_renda_origem   FOREIGN KEY (id_origem_renda) REFERENCES tb_origem_renda(id_origem_renda),
    CONSTRAINT fk_renda_pedido   FOREIGN KEY (id_pedido)       REFERENCES tb_pedido(id_pedido),
    CONSTRAINT fk_renda_feira    FOREIGN KEY (id_feira)        REFERENCES tb_feira(id_feira) ON DELETE SET NULL
);

CREATE TABLE tb_categoria_despesa (
    id_categoria_despesa        INT AUTO_INCREMENT PRIMARY KEY,
    nome_categoria_despesa      VARCHAR(80)  NOT NULL,
    descricao_categoria_despesa VARCHAR(150),
    CONSTRAINT uk_categoria_despesa_nome UNIQUE (nome_categoria_despesa)
);

CREATE TABLE tb_despesa (
    id_despesa           INT AUTO_INCREMENT PRIMARY KEY,
    id_feirante          INT           NOT NULL,
    id_categoria_despesa INT           NOT NULL,
    id_pedido            INT,                           -- preenchido só na taxa automática do Xepa+
    id_feira             INT,                           -- opcional: feira a que a despesa se refere
    descricao_despesa    VARCHAR(150)  NOT NULL,
    quantidade_despesa   DECIMAL(10,2) NOT NULL DEFAULT 1.00,
    valor_unitario       DECIMAL(10,2) NOT NULL,
    valor_despesa        DECIMAL(10,2) AS (quantidade_despesa * valor_unitario) STORED, -- calculado pelo banco
    data_despesa         DATE          NOT NULL,
    data_cadastro        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_despesa_feirante_data (id_feirante, data_despesa),
    CONSTRAINT uk_despesa_pedido     UNIQUE (id_pedido),
    CONSTRAINT ck_despesa_quantidade CHECK (quantidade_despesa > 0),
    CONSTRAINT ck_despesa_valor      CHECK (valor_unitario > 0),
    CONSTRAINT fk_despesa_feirante  FOREIGN KEY (id_feirante)          REFERENCES tb_feirante(id_feirante),
    CONSTRAINT fk_despesa_categoria FOREIGN KEY (id_categoria_despesa) REFERENCES tb_categoria_despesa(id_categoria_despesa),
    CONSTRAINT fk_despesa_pedido    FOREIGN KEY (id_pedido)            REFERENCES tb_pedido(id_pedido),
    CONSTRAINT fk_despesa_feira     FOREIGN KEY (id_feira)             REFERENCES tb_feira(id_feira) ON DELETE SET NULL
);

-- Saque via Pix do saldo do Xepa+ (vendas pelo app já sem comissão, menos os saques não recusados)
CREATE TABLE tb_saque (
    id_saque             INT AUTO_INCREMENT PRIMARY KEY,
    id_feirante          INT           NOT NULL,
    valor_saque          DECIMAL(10,2) NOT NULL,
    tipo_chave_pix       VARCHAR(10)   NOT NULL,
    chave_pix            VARCHAR(100)  NOT NULL,
    status_saque         VARCHAR(20)   NOT NULL DEFAULT 'SOLICITADO',
    id_transacao_gateway VARCHAR(100),                  -- ID retornado pelo provedor do Pix
    data_solicitacao     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_conclusao       DATETIME,                      -- preenchida quando concluído ou recusado
    INDEX idx_saque_feirante_data (id_feirante, data_solicitacao),
    CONSTRAINT ck_saque_valor  CHECK (valor_saque > 0),
    CONSTRAINT ck_saque_tipo   CHECK (tipo_chave_pix IN ('CPF', 'CNPJ', 'EMAIL', 'CELULAR', 'ALEATORIA')),
    CONSTRAINT ck_saque_status CHECK (status_saque IN ('SOLICITADO', 'CONCLUIDO', 'RECUSADO')),
    CONSTRAINT fk_saque_feirante FOREIGN KEY (id_feirante) REFERENCES tb_feirante(id_feirante)
);

-- Saldo disponível para saque: o backend confere este valor antes de aceitar um novo saque
CREATE VIEW vw_saldo_feirante AS
SELECT
    f.id_feirante,
    COALESCE(r.recebido, 0)                          AS valor_recebido,
    COALESCE(s.sacado, 0)                            AS valor_sacado,
    COALESCE(r.recebido, 0) - COALESCE(s.sacado, 0)  AS saldo_disponivel
FROM tb_feirante f
LEFT JOIN (
    SELECT id_feirante, SUM(valor_renda) AS recebido
    FROM tb_renda
    WHERE id_pedido IS NOT NULL                     -- só o que foi vendido pelo app fica no Xepa+
    GROUP BY id_feirante
) r ON r.id_feirante = f.id_feirante
LEFT JOIN (
    SELECT id_feirante, SUM(valor_saque) AS sacado
    FROM tb_saque
    WHERE status_saque <> 'RECUSADO'
    GROUP BY id_feirante
) s ON s.id_feirante = f.id_feirante;

INSERT INTO tb_tipo_pagamento (metodo_pagamento) VALUES
    ('PIX'), ('CARTAO_CREDITO'), ('CARTAO_DEBITO'), ('DINHEIRO');

INSERT INTO tb_categoria (nome_categoria) VALUES
    ('Frutas'), ('Verduras'), ('Legumes'), ('Temperos'), ('Ovos'), ('Outros');

INSERT INTO tb_origem_renda (nome_origem_renda) VALUES
    ('Venda na feira'),
    ('Venda de xepa pelo Xepa+'),                       -- usada nas rendas automáticas dos pedidos
    ('Encomenda'),
    ('Entrega em domicílio'),
    ('Venda para comércio'),
    ('Outros');

INSERT INTO tb_categoria_despesa (nome_categoria_despesa, descricao_categoria_despesa) VALUES
    ('Mercadoria', 'Compra de produtos para revenda'),
    ('Ajudantes/funcionários', 'Diárias e pagamentos de quem ajuda na barraca'),
    ('Transporte', 'Frete e estacionamento'),
    ('Combustível', 'Combustível do veículo da barraca'),
    ('Embalagens e sacolas', 'Sacolas, bandejas, caixas'),
    ('Barraca e equipamentos', 'Lona, balança, caixotes e outros equipamentos'),
    ('Manutenção', 'Consertos da barraca, veículo e equipamentos'),
    ('Taxas e licenças', 'Taxas da feira, licenças, mensalidade do plano do app'),
    ('Taxa do Xepa+', 'Comissão do plano descontada de cada venda pelo app (lançada automaticamente)'),
    ('Alimentação', 'Refeições durante a feira'),
    ('Outras despesas', 'Demais despesas');

-- Planos (comissão: Grátis 15%, Crescer 8%, Pro 5%). Precisam de um colaborador já cadastrado:
-- INSERT INTO tb_plano (id_colaborador, nome_plano, valor_plano, percentual_comissao) VALUES
--     (1, 'Grátis', 0.00, 15.00), (1, 'Crescer', 29.90, 8.00), (1, 'Pro', 59.90, 5.00);