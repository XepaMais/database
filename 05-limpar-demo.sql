-- =====================================================================
-- Xepa+ | 05-limpar-demo.sql
-- Apaga SÓ os dados fictícios do 04-seed-demo.sql (contas @demo.xepamais.com.br
-- e tudo ligado a elas). Contas reais não são tocadas.
-- =====================================================================
USE db_xepa;
START TRANSACTION;

CREATE TEMPORARY TABLE demo_conta AS SELECT id_conta FROM tb_conta WHERE email_conta LIKE '%@demo.xepamais.com.br';
CREATE TEMPORARY TABLE demo_feirante AS SELECT id_feirante FROM tb_feirante WHERE id_conta IN (SELECT id_conta FROM demo_conta);
CREATE TEMPORARY TABLE demo_consumidor AS SELECT id_consumidor FROM tb_consumidor WHERE id_conta IN (SELECT id_conta FROM demo_conta);
CREATE TEMPORARY TABLE demo_pedido AS SELECT id_pedido FROM tb_pedido
    WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante) OR id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);
CREATE TEMPORARY TABLE demo_chat AS SELECT id_chat FROM tb_chat
    WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante) OR id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);

DELETE FROM tb_mensagem WHERE id_chat IN (SELECT id_chat FROM demo_chat);
DELETE FROM tb_chat WHERE id_chat IN (SELECT id_chat FROM demo_chat);
DELETE FROM tb_avaliacao WHERE id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_renda WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante) OR id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_despesa WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante) OR id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_saque WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_pagamento WHERE id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_item_pedido WHERE id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_pedido WHERE id_pedido IN (SELECT id_pedido FROM demo_pedido);
DELETE FROM tb_item_carrinho WHERE id_xepa IN (SELECT x.id_xepa FROM tb_xepa x JOIN tb_produto p ON p.id_produto = x.id_produto WHERE p.id_feirante IN (SELECT id_feirante FROM demo_feirante));
DELETE FROM tb_xepa WHERE id_produto IN (SELECT id_produto FROM tb_produto WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante));
DELETE FROM tb_produto WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
-- Funcionários das barracas cadastrados pelos visitantes da demonstração.
DELETE FROM tb_funcionario_feira WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_feirante_feira WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_feirante WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_item_carrinho WHERE id_carrinho IN (SELECT id_carrinho FROM tb_carrinho WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor));
DELETE FROM tb_carrinho WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);
DELETE FROM tb_consumidor WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);
-- Conversas com a Xepinha e fotos enviadas pelos visitantes da demonstração.
DELETE FROM tb_mensagem_ia WHERE id_conta IN (SELECT id_conta FROM demo_conta);
DELETE FROM tb_conversa_ia WHERE id_conta IN (SELECT id_conta FROM demo_conta);
DELETE FROM tb_imagem WHERE id_conta IN (SELECT id_conta FROM demo_conta);
DELETE FROM tb_dispositivo_sessao WHERE id_conta IN (SELECT id_conta FROM demo_conta);
DELETE FROM tb_conta WHERE id_conta IN (SELECT id_conta FROM demo_conta);

COMMIT;
