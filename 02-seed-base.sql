-- =====================================================================
-- Xepa+ | 02-seed-base.sql
-- Dados de referência que o sistema precisa para funcionar (não são dados
-- de usuários). INSERT IGNORE: pode rodar de novo sem duplicar nada.
-- Fonte: definidos pela equipe (planos e comissões em documentacao/08-financeiro.md).
-- =====================================================================
USE db_xepa;


-- Formas de pagamento aceitas no checkout
INSERT IGNORE INTO `tb_tipo_pagamento` (`id_tipo_pagamento`, `metodo_pagamento`) VALUES (2,'CARTAO_CREDITO');
INSERT IGNORE INTO `tb_tipo_pagamento` (`id_tipo_pagamento`, `metodo_pagamento`) VALUES (3,'CARTAO_DEBITO');
INSERT IGNORE INTO `tb_tipo_pagamento` (`id_tipo_pagamento`, `metodo_pagamento`) VALUES (4,'DINHEIRO');
INSERT IGNORE INTO `tb_tipo_pagamento` (`id_tipo_pagamento`, `metodo_pagamento`) VALUES (1,'PIX');

-- Categorias das xepas (peso médio usado no cálculo de impacto: kg de alimento salvo)
INSERT IGNORE INTO `tb_categoria` (`id_categoria`, `nome_categoria`, `peso_medio_kg`) VALUES (1,'Verduras e legumes',2.00);
INSERT IGNORE INTO `tb_categoria` (`id_categoria`, `nome_categoria`, `peso_medio_kg`) VALUES (2,'Frutas',2.00);
INSERT IGNORE INTO `tb_categoria` (`id_categoria`, `nome_categoria`, `peso_medio_kg`) VALUES (3,'Tempero',0.30);
INSERT IGNORE INTO `tb_categoria` (`id_categoria`, `nome_categoria`, `peso_medio_kg`) VALUES (4,'Completa',3.00);

-- Categorias de gasto do financeiro do feirante
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (1,'Mercadoria','Compra de produtos para revenda');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (2,'Ajudantes/funcionários','Diárias e pagamentos de quem ajuda na barraca');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (3,'Transporte','Frete e estacionamento');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (4,'Combustível','Combustível do veículo da barraca');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (5,'Embalagens e sacolas','Sacolas, bandejas, caixas');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (6,'Barraca e equipamentos','Lona, balança, caixotes e outros equipamentos');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (7,'Manutenção','Consertos da barraca, veículo e equipamentos');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (8,'Taxas e licenças','Taxas da feira, licenças, mensalidade do plano do app');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (9,'Taxa do Xepa+','Comissão do plano descontada de cada venda pelo app (lançada automaticamente)');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (10,'Alimentação','Refeições durante a feira');
INSERT IGNORE INTO `tb_categoria_despesa` (`id_categoria_despesa`, `nome_categoria_despesa`, `descricao_categoria_despesa`) VALUES (11,'Outras despesas','Demais despesas');

-- Origens de renda do financeiro do feirante ("Venda de xepa pelo Xepa+" é lançada automaticamente a cada pedido)
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (3,'Encomenda');
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (4,'Entrega em domicílio');
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (6,'Outros');
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (2,'Venda de xepa pelo Xepa+');
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (1,'Venda na feira');
INSERT IGNORE INTO `tb_origem_renda` (`id_origem_renda`, `nome_origem_renda`) VALUES (5,'Venda para comércio');

-- Planos do feirante: Semente (grátis, 15% de comissão), Broto (R$ 29,90, 8%) e Colheita (R$ 59,90, 5%)
INSERT IGNORE INTO `tb_plano` (`id_plano`, `codigo_plano`, `id_colaborador`, `nome_plano`, `descricao_plano`, `valor_plano`, `percentual_comissao`, `ativo`) VALUES (1,'gratis',NULL,'Semente','Ideal para quem está começando agora e quer dar os primeiros passos sem nenhum investimento inicial.',0.00,15.00,1);
INSERT IGNORE INTO `tb_plano` (`id_plano`, `codigo_plano`, `id_colaborador`, `nome_plano`, `descricao_plano`, `valor_plano`, `percentual_comissao`, `ativo`) VALUES (2,'crescer',NULL,'Broto','Perfeito para negócios em expansão que precisam de mais flexibilidade e recursos avançados.',29.90,8.00,1);
INSERT IGNORE INTO `tb_plano` (`id_plano`, `codigo_plano`, `id_colaborador`, `nome_plano`, `descricao_plano`, `valor_plano`, `percentual_comissao`, `ativo`) VALUES (3,'pro',NULL,'Colheita','A solução completa para feirante que busca alta performance, controle total e máxima produtividade.',59.90,5.00,1);

-- Categorias de receitas da área "Cozinha"
INSERT IGNORE INTO `tb_categoria_receita` (`id_categoria_receita`, `nome_categoria_receita`) VALUES (4,'Aproveitamento integral');
INSERT IGNORE INTO `tb_categoria_receita` (`id_categoria_receita`, `nome_categoria_receita`) VALUES (3,'Doces');
INSERT IGNORE INTO `tb_categoria_receita` (`id_categoria_receita`, `nome_categoria_receita`) VALUES (5,'Rápidas');
INSERT IGNORE INTO `tb_categoria_receita` (`id_categoria_receita`, `nome_categoria_receita`) VALUES (1,'Saladas');
INSERT IGNORE INTO `tb_categoria_receita` (`id_categoria_receita`, `nome_categoria_receita`) VALUES (2,'Sopas');

-- Receitas para aproveitar a xepa (as mesmas que a API cria em receita/ReceitasIniciais.java)
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (1,'salada-caesar',NULL,'Salada caesar','Saladas','Fácil',NULL,NULL,15,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (2,'caldo-verde',NULL,'Caldo verde','Sopas','Fácil',NULL,NULL,35,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (3,'bolo-banana',NULL,'Bolo de banana','Doces','Média',NULL,NULL,45,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (4,'talos-salteados',NULL,'Talos salteados com alho','Aproveitamento integral','Fácil',NULL,NULL,20,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (5,'tomates-recheados',NULL,'Tomates recheados','Rápidas','Média',NULL,NULL,25,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (6,'creme-cenoura',NULL,'Creme de cenoura','Sopas','Fácil',NULL,NULL,30,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (7,'salada-frutas',NULL,'Salada de frutas da estação','Doces','Fácil',NULL,NULL,12,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (8,'refogado-colorido',NULL,'Refogado colorido','Aproveitamento integral','Fácil',NULL,NULL,18,NULL);
INSERT IGNORE INTO `tb_receita_culinaria` (`id_receita`, `codigo_receita`, `id_categoria_receita`, `titulo_receita`, `categoria_receita`, `dificuldade_receita`, `imagem_receita`, `modo_preparo`, `tempo_preparo`, `dificuldade`) VALUES (9,'vitamina-banana-mamao',NULL,'Vitamina de banana e mamão','Sucos','Fácil',NULL,NULL,5,NULL);

-- Ingredientes de cada receita
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (1,1,NULL,'tomate',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (2,1,NULL,'cenoura',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (3,1,NULL,'alface',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (4,2,NULL,'couve',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (5,2,NULL,'batata',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (6,2,NULL,'cebola',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (7,3,NULL,'banana',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (8,3,NULL,'aveia',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (9,3,NULL,'canela',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (10,4,NULL,'couve',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (11,4,NULL,'alho',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (12,4,NULL,'cenoura',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (13,5,NULL,'tomate',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (14,5,NULL,'arroz',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (15,5,NULL,'queijo',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (16,6,NULL,'cenoura',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (17,6,NULL,'batata',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (18,6,NULL,'gengibre',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (19,7,NULL,'banana',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (20,7,NULL,'mamão',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (21,7,NULL,'laranja',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (22,8,NULL,'cenoura',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (23,8,NULL,'couve',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (24,8,NULL,'cebola',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (25,9,NULL,'banana',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (26,9,NULL,'mamão',NULL);
INSERT IGNORE INTO `tb_ingrediente_receita` (`id_ingrediente`, `id_receita`, `id_categoria`, `nome_ingrediente`, `quantidade_ingrediente`) VALUES (27,9,NULL,'leite',NULL);
