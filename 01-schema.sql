-- =====================================================================
-- Xepa+ | 01-schema.sql
-- Estrutura completa do banco db_xepa (MySQL 8): 36 tabelas, chaves
-- primárias, estrangeiras, índices e restrições (CHECK / UNIQUE).
--
-- 36 tabelas + 1 view (vw_saldo_feirante).
-- Gerado a partir do banco real: script base da equipe + todas as
-- atualizações feitas pela API ao iniciar (config/AtualizacaoBanco.java).
-- A explicação de cada tabela e campo está no README.md (dicionário de dados).
--
-- Uso:  mysql -u root -p < 01-schema.sql
-- Depois rode, nesta ordem: 02-seed-base.sql, 03-seed-feiras.sql, 04-seed-demo.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS db_xepa
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;
USE db_xepa;

-- As tabelas estão em ordem alfabética; as chaves estrangeiras são conferidas no fim.
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `tb_avaliacao` (
  `id_avaliacao` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_consumidor` int NOT NULL,
  `id_feirante` int NOT NULL,
  `nota` tinyint NOT NULL,
  `comentario` text COLLATE utf8mb4_unicode_ci,
  `data_avaliacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_avaliacao`),
  UNIQUE KEY `uk_avaliacao_pedido` (`id_pedido`),
  KEY `fk_avaliacao_consumidor` (`id_consumidor`),
  KEY `fk_avaliacao_feirante` (`id_feirante`),
  CONSTRAINT `fk_avaliacao_consumidor` FOREIGN KEY (`id_consumidor`) REFERENCES `tb_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_avaliacao_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `fk_avaliacao_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`),
  CONSTRAINT `ck_avaliacao_nota` CHECK ((`nota` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_carrinho` (
  `id_carrinho` int NOT NULL AUTO_INCREMENT,
  `id_consumidor` int NOT NULL,
  `data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_carrinho`),
  UNIQUE KEY `uk_carrinho_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_carrinho_consumidor` FOREIGN KEY (`id_consumidor`) REFERENCES `tb_consumidor` (`id_consumidor`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_categoria` (
  `id_categoria` int NOT NULL AUTO_INCREMENT,
  `nome_categoria` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `peso_medio_kg` decimal(5,2) NOT NULL DEFAULT '2.00',
  PRIMARY KEY (`id_categoria`),
  UNIQUE KEY `uk_categoria_nome` (`nome_categoria`),
  CONSTRAINT `ck_categoria_peso` CHECK ((`peso_medio_kg` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_categoria_despesa` (
  `id_categoria_despesa` int NOT NULL AUTO_INCREMENT,
  `nome_categoria_despesa` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descricao_categoria_despesa` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_categoria_despesa`),
  UNIQUE KEY `uk_categoria_despesa_nome` (`nome_categoria_despesa`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_categoria_receita` (
  `id_categoria_receita` int NOT NULL AUTO_INCREMENT,
  `nome_categoria_receita` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_categoria_receita`),
  UNIQUE KEY `uk_categoria_receita_nome` (`nome_categoria_receita`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_chat` (
  `id_chat` int NOT NULL AUTO_INCREMENT,
  `id_consumidor` int NOT NULL,
  `id_feirante` int NOT NULL,
  `id_pedido` int DEFAULT NULL,
  `id_xepa` int DEFAULT NULL,
  `status_chat` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RECENTE',
  `data_inicio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_finalizacao` datetime DEFAULT NULL,
  `leitura_consumidor` datetime DEFAULT NULL,
  `leitura_feirante` datetime DEFAULT NULL,
  PRIMARY KEY (`id_chat`),
  UNIQUE KEY `uk_chat_pedido` (`id_pedido`),
  KEY `idx_chat_feirante_status` (`id_feirante`,`status_chat`),
  KEY `fk_chat_consumidor` (`id_consumidor`),
  KEY `fk_chat_xepa` (`id_xepa`),
  CONSTRAINT `fk_chat_consumidor` FOREIGN KEY (`id_consumidor`) REFERENCES `tb_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_chat_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `fk_chat_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`),
  CONSTRAINT `fk_chat_xepa` FOREIGN KEY (`id_xepa`) REFERENCES `tb_xepa` (`id_xepa`),
  CONSTRAINT `ck_chat_assunto` CHECK (((`id_pedido` is null) or (`id_xepa` is null))),
  CONSTRAINT `ck_chat_status` CHECK ((`status_chat` in (_utf8mb4'RECENTE',_utf8mb4'FINALIZADA')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_colaborador` (
  `id_colaborador` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  PRIMARY KEY (`id_colaborador`),
  UNIQUE KEY `uk_colaborador_conta` (`id_conta`),
  CONSTRAINT `fk_colaborador_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_consumidor` (
  `id_consumidor` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `recebimento_preferido` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RETIRADA',
  `cep_entrega` char(8) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `logradouro_entrega` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_entrega` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `complemento_entrega` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bairro_entrega` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cidade_entrega` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uf_entrega` char(2) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_consumidor`),
  UNIQUE KEY `uk_consumidor_conta` (`id_conta`),
  CONSTRAINT `fk_consumidor_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_conta` (
  `id_conta` int NOT NULL AUTO_INCREMENT,
  `nome_conta` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cpf_conta` char(11) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_conta` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `senha_conta` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefone_conta` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_nascimento` date DEFAULT NULL,
  `foto_conta` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  `data_cadastro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `aceite_termos_em` datetime DEFAULT NULL,
  `versao_termos` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aceite_marketing` tinyint(1) NOT NULL DEFAULT '0',
  `data_exclusao` datetime DEFAULT NULL,
  PRIMARY KEY (`id_conta`),
  UNIQUE KEY `uk_conta_cpf` (`cpf_conta`),
  UNIQUE KEY `uk_conta_email` (`email_conta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_conversa_ia` (
  `id_conversa_ia` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `titulo_conversa` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_conversa_ia`),
  KEY `idx_conversa_ia_conta` (`id_conta`),
  CONSTRAINT `fk_conversa_ia_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_despesa` (
  `id_despesa` int NOT NULL AUTO_INCREMENT,
  `id_feirante` int NOT NULL,
  `id_categoria_despesa` int NOT NULL,
  `id_pedido` int DEFAULT NULL,
  `id_feira` int DEFAULT NULL,
  `descricao_despesa` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantidade_despesa` decimal(10,2) NOT NULL DEFAULT '1.00',
  `valor_unitario` decimal(10,2) NOT NULL,
  `valor_despesa` decimal(10,2) GENERATED ALWAYS AS ((`quantidade_despesa` * `valor_unitario`)) STORED,
  `data_despesa` date NOT NULL,
  `data_cadastro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_despesa`),
  UNIQUE KEY `uk_despesa_pedido` (`id_pedido`),
  KEY `idx_despesa_feirante_data` (`id_feirante`,`data_despesa`),
  KEY `fk_despesa_categoria` (`id_categoria_despesa`),
  KEY `fk_despesa_feira` (`id_feira`),
  CONSTRAINT `fk_despesa_categoria` FOREIGN KEY (`id_categoria_despesa`) REFERENCES `tb_categoria_despesa` (`id_categoria_despesa`),
  CONSTRAINT `fk_despesa_feira` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`) ON DELETE SET NULL,
  CONSTRAINT `fk_despesa_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `fk_despesa_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`),
  CONSTRAINT `ck_despesa_quantidade` CHECK ((`quantidade_despesa` > 0)),
  CONSTRAINT `ck_despesa_valor` CHECK ((`valor_unitario` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_dispositivo_sessao` (
  `id_dispositivo` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `nome_aparelho` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo_aparelho` varchar(12) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `navegador` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `token_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expira_em` datetime NOT NULL,
  `ultimo_acesso` datetime DEFAULT NULL,
  `revogado` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_dispositivo`),
  UNIQUE KEY `uk_dispositivo_token` (`token_hash`),
  KEY `fk_dispositivo_conta` (`id_conta`),
  CONSTRAINT `fk_dispositivo_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_endereco` (
  `id_endereco` int NOT NULL AUTO_INCREMENT,
  `id_consumidor` int NOT NULL,
  `cep_endereco` char(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logradouro` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_endereco` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `complemento` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bairro` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cidade` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uf` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `principal` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_endereco`),
  KEY `fk_endereco_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_endereco_consumidor` FOREIGN KEY (`id_consumidor`) REFERENCES `tb_consumidor` (`id_consumidor`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_entrega` (
  `id_entrega` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_feira` int NOT NULL,
  `cep_entrega` char(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logradouro` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_entrega` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `complemento` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bairro` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cidade` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uf` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `distancia_km` decimal(5,1) NOT NULL,
  `valor_frete` decimal(10,2) NOT NULL,
  `tempo_minimo` smallint DEFAULT NULL,
  `tempo_maximo` smallint DEFAULT NULL,
  `id_entrega_gateway` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_entrega` datetime DEFAULT NULL,
  PRIMARY KEY (`id_entrega`),
  UNIQUE KEY `uk_entrega_pedido_feira` (`id_pedido`,`id_feira`),
  KEY `fk_entrega_feira` (`id_feira`),
  CONSTRAINT `fk_entrega_feira` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`),
  CONSTRAINT `fk_entrega_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `ck_entrega_distancia` CHECK ((`distancia_km` >= 0)),
  CONSTRAINT `ck_entrega_frete` CHECK ((`valor_frete` >= 0)),
  CONSTRAINT `ck_entrega_tempo` CHECK ((`tempo_maximo` >= `tempo_minimo`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_feira` (
  `id_feira` int NOT NULL AUTO_INCREMENT,
  `nome_feira` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `endereco_feira` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_feira` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cep_feira` char(8) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cidade_feira` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uf_feira` char(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `horario_inicio` time DEFAULT NULL,
  `horario_fim` time DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  PRIMARY KEY (`id_feira`),
  KEY `idx_feira_cidade` (`uf_feira`,`cidade_feira`),
  CONSTRAINT `ck_feira_horario` CHECK ((`horario_fim` > `horario_inicio`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_feira_dia` (
  `id_feira` int NOT NULL,
  `dia_semana` tinyint NOT NULL,
  PRIMARY KEY (`id_feira`,`dia_semana`),
  CONSTRAINT `fk_feira_dia` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`) ON DELETE CASCADE,
  CONSTRAINT `ck_feira_dia` CHECK ((`dia_semana` between 1 and 7))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_feirante` (
  `id_feirante` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `id_plano` int DEFAULT NULL,
  `nome_fantasia` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `cnpj_feirante` char(14) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ccm_feirante` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `matricula_feirante` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `validade_matricula` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titular_matricula` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `grupo_comercio` varchar(60) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `titular_feirante` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_feirante`),
  UNIQUE KEY `uk_feirante_conta` (`id_conta`),
  UNIQUE KEY `uk_feirante_cnpj` (`cnpj_feirante`),
  UNIQUE KEY `uk_feirante_matricula` (`matricula_feirante`),
  KEY `fk_feirante_plano` (`id_plano`),
  CONSTRAINT `fk_feirante_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`),
  CONSTRAINT `fk_feirante_plano` FOREIGN KEY (`id_plano`) REFERENCES `tb_plano` (`id_plano`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_feirante_feira` (
  `id_feirante` int NOT NULL,
  `id_feira` int NOT NULL,
  PRIMARY KEY (`id_feirante`,`id_feira`),
  KEY `fk_ff_feira` (`id_feira`),
  CONSTRAINT `fk_ff_feira` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`) ON DELETE CASCADE,
  CONSTRAINT `fk_ff_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_funcionario_feira` (
  `id_funcionario` int NOT NULL AUTO_INCREMENT,
  `id_feirante` int NOT NULL,
  `id_feira` int NOT NULL,
  `nome_funcionario` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_funcionario`),
  KEY `fk_funcionario_feirante_feira` (`id_feirante`,`id_feira`),
  CONSTRAINT `fk_funcionario_feirante_feira` FOREIGN KEY (`id_feirante`, `id_feira`) REFERENCES `tb_feirante_feira` (`id_feirante`, `id_feira`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_imagem` (
  `id_imagem` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `tipo_conteudo` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dados_imagem` mediumblob NOT NULL,
  `data_cadastro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_imagem`),
  KEY `fk_imagem_conta` (`id_conta`),
  CONSTRAINT `fk_imagem_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_ingrediente_receita` (
  `id_ingrediente` int NOT NULL AUTO_INCREMENT,
  `id_receita` int NOT NULL,
  `id_categoria` int DEFAULT NULL,
  `nome_ingrediente` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantidade_ingrediente` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_ingrediente`),
  KEY `fk_ingrediente_receita` (`id_receita`),
  KEY `fk_ingrediente_categoria` (`id_categoria`),
  CONSTRAINT `fk_ingrediente_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `tb_categoria` (`id_categoria`),
  CONSTRAINT `fk_ingrediente_receita` FOREIGN KEY (`id_receita`) REFERENCES `tb_receita_culinaria` (`id_receita`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_item_carrinho` (
  `id_item_carrinho` int NOT NULL AUTO_INCREMENT,
  `id_carrinho` int NOT NULL,
  `id_xepa` int NOT NULL,
  `quantidade_item` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id_item_carrinho`),
  UNIQUE KEY `uk_item_carrinho` (`id_carrinho`,`id_xepa`),
  KEY `fk_item_carrinho_xepa` (`id_xepa`),
  CONSTRAINT `fk_item_carrinho_carrinho` FOREIGN KEY (`id_carrinho`) REFERENCES `tb_carrinho` (`id_carrinho`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_carrinho_xepa` FOREIGN KEY (`id_xepa`) REFERENCES `tb_xepa` (`id_xepa`) ON DELETE CASCADE,
  CONSTRAINT `ck_item_carrinho_qtd` CHECK ((`quantidade_item` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_item_pedido` (
  `id_item_pedido` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_xepa` int NOT NULL,
  `quantidade_item` decimal(10,2) NOT NULL,
  `preco_unitario` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id_item_pedido`),
  UNIQUE KEY `uk_item_pedido` (`id_pedido`,`id_xepa`),
  KEY `fk_item_pedido_xepa` (`id_xepa`),
  CONSTRAINT `fk_item_pedido_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_item_pedido_xepa` FOREIGN KEY (`id_xepa`) REFERENCES `tb_xepa` (`id_xepa`),
  CONSTRAINT `ck_item_pedido_preco` CHECK ((`preco_unitario` >= 0)),
  CONSTRAINT `ck_item_pedido_qtd` CHECK ((`quantidade_item` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_mensagem` (
  `id_mensagem` int NOT NULL AUTO_INCREMENT,
  `id_chat` int NOT NULL,
  `id_conta` int DEFAULT NULL,
  `texto_mensagem` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_envio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lida` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_mensagem`),
  KEY `idx_mensagem_chat_data` (`id_chat`,`data_envio`),
  KEY `fk_mensagem_conta` (`id_conta`),
  CONSTRAINT `fk_mensagem_chat` FOREIGN KEY (`id_chat`) REFERENCES `tb_chat` (`id_chat`) ON DELETE CASCADE,
  CONSTRAINT `fk_mensagem_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_mensagem_ia` (
  `id_mensagem_ia` int NOT NULL AUTO_INCREMENT,
  `id_conta` int NOT NULL,
  `id_conversa_ia` int DEFAULT NULL,
  `papel` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `texto_mensagem_ia` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `data_envio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_mensagem_ia`),
  KEY `idx_mensagem_ia_conta_data` (`id_conta`,`data_envio`),
  KEY `fk_mensagem_ia_conversa` (`id_conversa_ia`),
  CONSTRAINT `fk_mensagem_ia_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`) ON DELETE CASCADE,
  CONSTRAINT `fk_mensagem_ia_conversa` FOREIGN KEY (`id_conversa_ia`) REFERENCES `tb_conversa_ia` (`id_conversa_ia`) ON DELETE CASCADE,
  CONSTRAINT `ck_mensagem_ia_papel` CHECK ((`papel` in (_utf8mb4'USUARIO',_utf8mb4'IA')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_mensagem_suporte` (
  `id_mensagem_suporte` int NOT NULL AUTO_INCREMENT,
  `id_conta` int DEFAULT NULL,
  `nome_remetente` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_remetente` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `perfil_remetente` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL,
  `assunto` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mensagem` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `status_suporte` varchar(12) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ABERTA',
  `data_envio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_mensagem_suporte`),
  KEY `fk_suporte_conta` (`id_conta`),
  CONSTRAINT `fk_suporte_conta` FOREIGN KEY (`id_conta`) REFERENCES `tb_conta` (`id_conta`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_origem_renda` (
  `id_origem_renda` int NOT NULL AUTO_INCREMENT,
  `nome_origem_renda` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_origem_renda`),
  UNIQUE KEY `uk_origem_renda_nome` (`nome_origem_renda`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_pagamento` (
  `id_pagamento` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_tipo_pagamento` int NOT NULL,
  `valor_pagamento` decimal(10,2) NOT NULL,
  `status_pagamento` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDENTE',
  `id_transacao_gateway` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_criacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_pagamento` datetime DEFAULT NULL,
  PRIMARY KEY (`id_pagamento`),
  KEY `fk_pagamento_pedido` (`id_pedido`),
  KEY `fk_pagamento_tipo` (`id_tipo_pagamento`),
  CONSTRAINT `fk_pagamento_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`),
  CONSTRAINT `fk_pagamento_tipo` FOREIGN KEY (`id_tipo_pagamento`) REFERENCES `tb_tipo_pagamento` (`id_tipo_pagamento`),
  CONSTRAINT `ck_pagamento_status` CHECK ((`status_pagamento` in (_utf8mb4'PENDENTE',_utf8mb4'APROVADO',_utf8mb4'RECUSADO',_utf8mb4'ESTORNADO'))),
  CONSTRAINT `ck_pagamento_valor` CHECK ((`valor_pagamento` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_pedido` (
  `id_pedido` int NOT NULL AUTO_INCREMENT,
  `id_consumidor` int NOT NULL,
  `id_feirante` int NOT NULL,
  `data_pedido` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status_pedido` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AGUARDANDO_PAGAMENTO',
  `tipo_recebimento` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RETIRADA',
  `valor_total` decimal(10,2) NOT NULL,
  `percentual_comissao` decimal(5,2) NOT NULL DEFAULT '0.00',
  `valor_comissao` decimal(10,2) NOT NULL DEFAULT '0.00',
  `codigo_retirada` char(4) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `endereco_entrega` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `taxa_entrega` decimal(10,2) NOT NULL DEFAULT '0.00',
  PRIMARY KEY (`id_pedido`),
  KEY `idx_pedido_feirante_status` (`id_feirante`,`status_pedido`),
  KEY `fk_pedido_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_pedido_consumidor` FOREIGN KEY (`id_consumidor`) REFERENCES `tb_consumidor` (`id_consumidor`),
  CONSTRAINT `fk_pedido_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `ck_pedido_comissao` CHECK (((`percentual_comissao` between 0 and 100) and (`valor_comissao` between 0 and `valor_total`))),
  CONSTRAINT `ck_pedido_recebimento` CHECK ((`tipo_recebimento` in (_utf8mb4'RETIRADA',_utf8mb4'ENTREGA'))),
  CONSTRAINT `ck_pedido_status` CHECK ((`status_pedido` in (_utf8mb4'AGUARDANDO_PAGAMENTO',_utf8mb4'PAGO',_utf8mb4'PRONTO_RETIRADA',_utf8mb4'RETIRADO',_utf8mb4'SAIU_PARA_ENTREGA',_utf8mb4'ENTREGUE',_utf8mb4'CANCELADO'))),
  CONSTRAINT `ck_pedido_valor` CHECK ((`valor_total` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_plano` (
  `id_plano` int NOT NULL AUTO_INCREMENT,
  `codigo_plano` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_colaborador` int DEFAULT NULL,
  `nome_plano` varchar(60) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descricao_plano` text COLLATE utf8mb4_unicode_ci,
  `valor_plano` decimal(10,2) NOT NULL DEFAULT '0.00',
  `percentual_comissao` decimal(5,2) NOT NULL DEFAULT '0.00',
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_plano`),
  UNIQUE KEY `uk_plano_nome` (`nome_plano`),
  UNIQUE KEY `uk_plano_codigo` (`codigo_plano`),
  KEY `fk_plano_colaborador` (`id_colaborador`),
  CONSTRAINT `fk_plano_colaborador` FOREIGN KEY (`id_colaborador`) REFERENCES `tb_colaborador` (`id_colaborador`),
  CONSTRAINT `ck_plano_comissao` CHECK ((`percentual_comissao` between 0 and 100)),
  CONSTRAINT `ck_plano_valor` CHECK ((`valor_plano` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_produto` (
  `id_produto` int NOT NULL AUTO_INCREMENT,
  `id_feirante` int NOT NULL,
  `id_categoria` int NOT NULL,
  `nome_produto` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descricao_produto` text COLLATE utf8mb4_unicode_ci,
  `imagem_produto` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unidade_medida` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `preco_referencia` decimal(10,2) DEFAULT NULL,
  `ativo` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_produto`),
  KEY `fk_produto_feirante` (`id_feirante`),
  KEY `fk_produto_categoria` (`id_categoria`),
  CONSTRAINT `fk_produto_categoria` FOREIGN KEY (`id_categoria`) REFERENCES `tb_categoria` (`id_categoria`),
  CONSTRAINT `fk_produto_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `ck_produto_preco` CHECK ((`preco_referencia` >= 0)),
  CONSTRAINT `ck_produto_unidade` CHECK ((`unidade_medida` in (_utf8mb4'KG',_utf8mb4'UNIDADE',_utf8mb4'MACO',_utf8mb4'DUZIA',_utf8mb4'BANDEJA')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_receita_culinaria` (
  `id_receita` int NOT NULL AUTO_INCREMENT,
  `codigo_receita` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `id_categoria_receita` int DEFAULT NULL,
  `titulo_receita` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `categoria_receita` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dificuldade_receita` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imagem_receita` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `modo_preparo` text COLLATE utf8mb4_unicode_ci,
  `tempo_preparo` int DEFAULT NULL,
  `dificuldade` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id_receita`),
  UNIQUE KEY `uk_receita_codigo` (`codigo_receita`),
  KEY `fk_receita_categoria` (`id_categoria_receita`),
  CONSTRAINT `fk_receita_categoria` FOREIGN KEY (`id_categoria_receita`) REFERENCES `tb_categoria_receita` (`id_categoria_receita`),
  CONSTRAINT `ck_receita_dificuldade` CHECK ((`dificuldade` in (_utf8mb4'FACIL',_utf8mb4'MEDIA',_utf8mb4'DIFICIL'))),
  CONSTRAINT `ck_receita_tempo` CHECK ((`tempo_preparo` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_renda` (
  `id_renda` int NOT NULL AUTO_INCREMENT,
  `id_feirante` int NOT NULL,
  `id_origem_renda` int NOT NULL,
  `id_pedido` int DEFAULT NULL,
  `id_feira` int DEFAULT NULL,
  `descricao_renda` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor_renda` decimal(10,2) NOT NULL,
  `data_renda` date NOT NULL,
  `data_cadastro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_renda`),
  UNIQUE KEY `uk_renda_pedido` (`id_pedido`),
  KEY `idx_renda_feirante_data` (`id_feirante`,`data_renda`),
  KEY `fk_renda_origem` (`id_origem_renda`),
  KEY `fk_renda_feira` (`id_feira`),
  CONSTRAINT `fk_renda_feira` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`) ON DELETE SET NULL,
  CONSTRAINT `fk_renda_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `fk_renda_origem` FOREIGN KEY (`id_origem_renda`) REFERENCES `tb_origem_renda` (`id_origem_renda`),
  CONSTRAINT `fk_renda_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `tb_pedido` (`id_pedido`),
  CONSTRAINT `ck_renda_valor` CHECK ((`valor_renda` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_saque` (
  `id_saque` int NOT NULL AUTO_INCREMENT,
  `id_feirante` int NOT NULL,
  `valor_saque` decimal(10,2) NOT NULL,
  `tipo_chave_pix` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `chave_pix` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status_saque` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SOLICITADO',
  `id_transacao_gateway` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_solicitacao` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_conclusao` datetime DEFAULT NULL,
  PRIMARY KEY (`id_saque`),
  KEY `idx_saque_feirante_data` (`id_feirante`,`data_solicitacao`),
  CONSTRAINT `fk_saque_feirante` FOREIGN KEY (`id_feirante`) REFERENCES `tb_feirante` (`id_feirante`),
  CONSTRAINT `ck_saque_status` CHECK ((`status_saque` in (_utf8mb4'SOLICITADO',_utf8mb4'CONCLUIDO',_utf8mb4'RECUSADO'))),
  CONSTRAINT `ck_saque_tipo` CHECK ((`tipo_chave_pix` in (_utf8mb4'CPF',_utf8mb4'CNPJ',_utf8mb4'EMAIL',_utf8mb4'CELULAR',_utf8mb4'ALEATORIA'))),
  CONSTRAINT `ck_saque_valor` CHECK ((`valor_saque` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_tipo_pagamento` (
  `id_tipo_pagamento` int NOT NULL AUTO_INCREMENT,
  `metodo_pagamento` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id_tipo_pagamento`),
  UNIQUE KEY `uk_tipo_pagamento` (`metodo_pagamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS `tb_xepa` (
  `id_xepa` int NOT NULL AUTO_INCREMENT,
  `id_produto` int NOT NULL,
  `id_feira` int NOT NULL,
  `quantidade_xepa` decimal(10,2) NOT NULL,
  `preco_xepa` decimal(10,2) NOT NULL,
  `validade_xepa` date DEFAULT NULL,
  `itens_xepa` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `local_retirada` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data_retirada` date NOT NULL,
  `horario_retirada_inicio` time NOT NULL,
  `horario_retirada_fim` time NOT NULL,
  `status_xepa` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DISPONIVEL',
  `data_cadastro` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `versao` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_xepa`),
  KEY `idx_xepa_busca` (`id_feira`,`status_xepa`,`data_retirada`),
  KEY `fk_xepa_produto` (`id_produto`),
  CONSTRAINT `fk_xepa_feira` FOREIGN KEY (`id_feira`) REFERENCES `tb_feira` (`id_feira`),
  CONSTRAINT `fk_xepa_produto` FOREIGN KEY (`id_produto`) REFERENCES `tb_produto` (`id_produto`),
  CONSTRAINT `ck_xepa_horario` CHECK ((`horario_retirada_fim` > `horario_retirada_inicio`)),
  CONSTRAINT `ck_xepa_preco` CHECK ((`preco_xepa` > 0)),
  CONSTRAINT `ck_xepa_quantidade` CHECK ((`quantidade_xepa` >= 0)),
  CONSTRAINT `ck_xepa_status` CHECK ((`status_xepa` in (_utf8mb4'DISPONIVEL',_utf8mb4'ESGOTADA',_utf8mb4'EXPIRADA',_utf8mb4'CANCELADA')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Saldo do feirante para saque: vendas pelo app (rendas ligadas a pedido) menos saques não recusados.
CREATE OR REPLACE VIEW vw_saldo_feirante AS
SELECT f.id_feirante,
       COALESCE(r.recebido, 0)                          AS valor_recebido,
       COALESCE(s.sacado, 0)                            AS valor_sacado,
       COALESCE(r.recebido, 0) - COALESCE(s.sacado, 0)  AS saldo_disponivel
FROM tb_feirante f
LEFT JOIN (SELECT id_feirante, SUM(valor_renda) AS recebido
           FROM tb_renda WHERE id_pedido IS NOT NULL GROUP BY id_feirante) r ON r.id_feirante = f.id_feirante
LEFT JOIN (SELECT id_feirante, SUM(valor_saque) AS sacado
           FROM tb_saque WHERE status_saque <> 'RECUSADO' GROUP BY id_feirante) s ON s.id_feirante = f.id_feirante;

SET FOREIGN_KEY_CHECKS = 1;
