<p align="center">
  <img src="https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/logo-texto-colorida.png" alt="Logo do Xepa+" width="260">
</p>

# Xepa+ | Banco de dados

Banco **MySQL 8** (`db_xepa`) do Xepa+, a plataforma que conecta feirantes com sobras do fim da feira (as *xepas*) a consumidores que querem comprar mais barato. Só a [API](https://github.com/XepaMais/backend) acessa o banco.

## Arquivos

| Arquivo | O que faz |
| --- | --- |
| [`01-schema.sql`](01-schema.sql) | Cria o banco com todas as tabelas, chaves, índices e a view |
| [`02-seed-base.sql`](02-seed-base.sql) | Dados de referência: pagamentos, categorias, planos e receitas |
| [`03-seed-feiras.sql`](03-seed-feiras.sql) | Feiras livres reais de São Paulo |
| [`04-seed-demo.sql`](04-seed-demo.sql) | Dados **fictícios** para demonstração |
| [`05-limpar-demo.sql`](05-limpar-demo.sql) | Apaga só os dados fictícios do `04` |

## Como rodar

```powershell
mysql -u root -p --default-character-set=utf8mb4 < 01-schema.sql
mysql -u root -p --default-character-set=utf8mb4 < 02-seed-base.sql
mysql -u root -p --default-character-set=utf8mb4 < 03-seed-feiras.sql
mysql -u root -p --default-character-set=utf8mb4 < 04-seed-demo.sql
```

**Contas de demonstração:** `nome.sobrenome@demo.xepamais.com.br`, senha `XepaDemo@2026`.
Exemplos: feirante `antonio.nakamura@demo.xepamais.com.br`, consumidor `henrique.mazza@demo.xepamais.com.br`.

## Modelo

| Contas, feiras e ofertas | Compra e pagamento | Comunicação, receitas e financeiro |
| --- | --- | --- |
| ![Contas, feiras e ofertas](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-contas-feiras-ofertas.png) | ![Compra e pagamento](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-compra-pagamento.png) | ![Comunicação, receitas e financeiro](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-comunicacao-receitas-financeiro.png) |

- Uma **conta** é de consumidor **ou** de feirante.
- O checkout cria **um pedido por feirante**, cada um com seu código de retirada.
- O item do pedido **guarda o preço pago**, então mudar o preço da xepa não altera pedidos antigos.
- A venda pelo app gera a **renda** do feirante automaticamente, já sem a comissão do plano.

## Tabelas

| Área | Tabelas |
| --- | --- |
| Contas e acesso | `tb_conta`, `tb_consumidor`, `tb_feirante`, `tb_colaborador`, `tb_dispositivo_sessao`, `tb_endereco`, `tb_imagem` |
| Feiras | `tb_plano`, `tb_feira`, `tb_feira_dia`, `tb_feirante_feira`, `tb_funcionario_feira` |
| Ofertas | `tb_categoria`, `tb_produto`, `tb_xepa` |
| Compra | `tb_carrinho`, `tb_item_carrinho`, `tb_tipo_pagamento`, `tb_pedido`, `tb_item_pedido`, `tb_pagamento`, `tb_entrega`, `tb_avaliacao` |
| Comunicação | `tb_chat`, `tb_mensagem`, `tb_conversa_ia`, `tb_mensagem_ia`, `tb_mensagem_suporte` |
| Financeiro | `tb_origem_renda`, `tb_renda`, `tb_categoria_despesa`, `tb_despesa`, `tb_saque`, `vw_saldo_feirante` (view) |
| Receitas | `tb_categoria_receita`, `tb_receita_culinaria`, `tb_ingrediente_receita` |

Tipos, chaves e regras de cada coluna estão no [`01-schema.sql`](01-schema.sql).

## Segurança e LGPD

- Senhas guardadas só como hash (PBKDF2-HMAC-SHA256).
- Nenhum dado de cartão é guardado.
- O banco só aceita conexões do próprio servidor da API.
- O aceite dos termos fica registrado na conta (`aceite_termos_em`, `versao_termos`).
- Ao excluir a conta, os dados pessoais são **anonimizados**; pedidos e rendas ficam guardados por obrigação fiscal.
- Os dados do seed de demonstração são inventados e usam o domínio `@demo.xepamais.com.br`.

Mais detalhes no repositório [documentacao](https://github.com/XepaMais/documentacao).

---

<p align="center"><a href="https://github.com/XepaMais">Xepa+</a> · menos desperdício, mais alimento</p>
