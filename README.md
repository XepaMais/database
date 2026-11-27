<p align="center">
  <img src="https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/logo-texto-colorida.png" alt="Logo do Xepa+" width="260">
</p>

# Xepa+ | Banco de dados

Banco relacional **MySQL 8** (`db_xepa`) do Xepa+, a plataforma que conecta feirantes com sobras do fim da feira (as *xepas*) a consumidores que querem comprar mais barato. A API em Java/Spring Boot ([repositório backend](https://github.com/XepaMais/backend)) é a única que acessa o banco; o site nunca fala direto com ele.

| | |
| --- | --- |
| **SGBD** | MySQL 8.0 (InnoDB, `utf8mb4_unicode_ci`) |
| **Tamanho** | 36 tabelas + 1 view, 53 chaves estrangeiras, 35 regras `CHECK` |
| **Acesso** | Spring Data JPA / Hibernate (`ddl-auto: none`: quem manda na estrutura são estes scripts) |
| **Hospedagem** | Amazon EC2, no mesmo servidor da API |

## Sumário

1. [Arquivos e como rodar](#1-arquivos-e-como-rodar)
2. [Modelo (diagramas e relacionamentos)](#2-modelo)
3. [Seed: dados de referência, feiras reais e demonstração](#3-seed-dados-que-alimentam-o-banco)
4. [Índices e desempenho](#4-índices-e-desempenho)
5. [Integridade e segurança](#5-integridade-e-segurança)
6. [LGPD no banco](#6-lgpd-no-banco)
7. [Evolução da estrutura](#7-evolução-da-estrutura)
8. [Dicionário de dados](#8-dicionário-de-dados)

---

## 1. Arquivos e como rodar

| Arquivo | O que faz | Pode rodar de novo? |
| --- | --- | --- |
| [`01-schema.sql`](01-schema.sql) | Cria o banco `db_xepa` com todas as tabelas, chaves, índices, regras e a view | Sim (`IF NOT EXISTS`) |
| [`02-seed-base.sql`](02-seed-base.sql) | Dados de referência: formas de pagamento, categorias, origens de renda, planos e receitas | Sim (`INSERT IGNORE`) |
| [`03-seed-feiras.sql`](03-seed-feiras.sql) | Feiras livres reais de São Paulo com dias, horários e coordenadas | Sim (confere pelo nome) |
| [`04-seed-demo.sql`](04-seed-demo.sql) | Dados **fictícios** do piloto: feirantes, consumidores, xepas, pedidos, financeiro, conversas e avaliações | Não: rode `05` antes |
| [`05-limpar-demo.sql`](05-limpar-demo.sql) | Apaga só os dados fictícios do `04` | Sim |
| [`scripts/gerar_seed_demo.py`](scripts/gerar_seed_demo.py) | Gera o `04` e o `05` | — |

**Criar o banco do zero (MySQL local):**

```powershell
mysql -u root -p --default-character-set=utf8mb4 < 01-schema.sql
mysql -u root -p --default-character-set=utf8mb4 < 02-seed-base.sql
mysql -u root -p --default-character-set=utf8mb4 < 03-seed-feiras.sql
mysql -u root -p --default-character-set=utf8mb4 < 04-seed-demo.sql
```

Na pasta `Xepa` da equipe, o `configurar-banco-local.ps1` faz tudo isso e cria o usuário que a API usa.

**Contas de demonstração** (criadas pelo `04`): `nome.sobrenome@demo.xepamais.com.br`, senha `XepaDemo@2026`. Exemplos: feirante `antonio.nakamura@demo.xepamais.com.br` (plano Colheita), consumidor `henrique.mazza@demo.xepamais.com.br`.

**Validação:** os cinco scripts foram executados em sequência num MySQL 8.0.46 vazio, a limpeza e o seed foram repetidos, e a API foi ligada nesse banco para conferir catálogo, login, financeiro, saldo, vendas, conversas, avaliações e consentimento.

---

## 2. Modelo

Diagramas (repositório [documentacao](https://github.com/XepaMais/documentacao)):

| Contas, feiras e ofertas | Compra e pagamento | Comunicação, receitas e financeiro |
| --- | --- | --- |
| ![Contas, feiras e ofertas](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-contas-feiras-ofertas.png) | ![Compra e pagamento](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-compra-pagamento.png) | ![Comunicação, receitas e financeiro](https://raw.githubusercontent.com/XepaMais/documentacao/main/assets/diagrama-banco-comunicacao-receitas-financeiro.png) |

**Relacionamentos principais**

```text
tb_conta 1─1 tb_consumidor ─< tb_pedido >─ tb_feirante 1─1 tb_conta
tb_conta 1─1 tb_feirante >─ tb_plano
tb_feirante >─< tb_feira            (tb_feirante_feira; dias em tb_feira_dia)
tb_feirante ─< tb_produto ─< tb_xepa >─ tb_feira
tb_pedido ─< tb_item_pedido >─ tb_xepa
tb_pedido ─< tb_pagamento >─ tb_tipo_pagamento
tb_pedido ─1 tb_avaliacao | tb_chat ─< tb_mensagem
tb_feirante ─< tb_renda / tb_despesa / tb_saque   (saldo: vw_saldo_feirante)
tb_conta ─< tb_conversa_ia ─< tb_mensagem_ia      (Xepinha)
```

- Uma **conta** é de consumidor **ou** de feirante (perfis 1 para 1).
- O checkout divide o carrinho em **um pedido por feirante**, cada um com seu código de retirada.
- O **item do pedido guarda o preço pago**, então mudar o preço da xepa não altera pedidos antigos.
- A **renda** de uma venda pelo app é criada junto com o pedido, já sem a comissão do plano.

---

## 3. Seed: dados que alimentam o banco

| Conjunto | Fonte | Método | Atualização |
| --- | --- | --- | --- |
| **Referência** (`02`) | Definidos pela equipe. Planos e comissões em [08-financeiro](https://github.com/XepaMais/documentacao/blob/main/08-financeiro.md) | Extraídos do banco depois que a API criou os padrões (`PlanosIniciais.java`, `ReceitasIniciais.java`) | Quando mudar um plano, categoria ou receita |
| **Feiras** (`03`) | Endereços reais levantados pela equipe na região do piloto (Freguesia do Ó, Brasilândia, Pirituba) e na Zona Oeste. Coordenadas do Google Maps | Escritos à mão, conferidos no mapa do site | A cada semestre, ou quando a Prefeitura mudar a lista |
| **Demonstração** (`04`) | Fictícios, baseados na pesquisa de campo ([05-pesquisas](https://github.com/XepaMais/documentacao/blob/main/05-pesquisas.md)): produtos, preços de fim de feira (30% a 60% do preço cheio) e rotina real dos feirantes | Gerados por `scripts/gerar_seed_demo.py` com semente fixa (sempre o mesmo resultado) | Sob demanda. As datas são relativas a "hoje", então nunca ficam velhas |

**O que o seed de demonstração cria:**
- 10 feirantes, um em cada plano, em 9 feiras;
- 30 consumidores com endereço;
- 40 produtos e 60 xepas: cerca de 40 à venda, e as demais esgotadas, vencidas ou canceladas;
- 40 pedidos em todas as situações (retirado, entregue, pago, pronto, saiu para entrega, cancelado), com itens, pagamentos (Pix e cartão), renda automática e conversa;
- avaliações de 3 a 5 estrelas;
- vendas na barraca, despesas por categoria e saques que nunca passam do saldo.

**Cuidados com dados pessoais no seed:**
- nomes, CPFs e CNPJs são **inventados**. CPF e CNPJ têm dígitos verificadores válidos, mas não pertencem a ninguém;
- os e-mails usam o domínio `@demo.xepamais.com.br`;
- todas as senhas são guardadas só como hash;
- o `05-limpar-demo.sql` remove tudo isso sem tocar em contas reais.

### Atualização das feiras

A [Relação Oficial de Feiras Livres](https://dados.prefeitura.sp.gov.br/dataset/relacao-de-feiras-livres) da Prefeitura de SP tem número, nome, dia da semana, endereço e CEP, mas não tem coordenadas. O arquivo publicado em novembro de 2026 traz só 22 feiras. Para ampliar a lista:
1. baixe o CSV;
2. converta o endereço em latitude e longitude com um serviço de geocodificação (Google Geocoding ou Nominatim);
3. gere novos `INSERT ... WHERE NOT EXISTS` no mesmo formato do `03`.

O `dia_semana` da Prefeitura já usa a mesma numeração do banco (1 = segunda).

---

## 4. Índices e desempenho

Além das chaves primárias, toda chave estrangeira e toda coluna `UNIQUE` têm índice. Os índices compostos abaixo existem para as consultas mais usadas pelo app:

| Índice | Tabela | Colunas | Para quê |
| --- | --- | --- | --- |
| `idx_chat_feirante_status` | `tb_chat` | id_feirante, status_chat | Lista de conversas "Recentes"/"Finalizadas" do feirante. |
| `idx_conversa_ia_conta` | `tb_conversa_ia` | id_conta | Conversas da Xepinha por feirante. |
| `idx_despesa_feirante_data` | `tb_despesa` | id_feirante, data_despesa | Financeiro: gastos do feirante por período. |
| `idx_feira_cidade` | `tb_feira` | uf_feira, cidade_feira | Filtro de feiras por cidade/UF (expansão para outras cidades). |
| `idx_mensagem_chat_data` | `tb_mensagem` | id_chat, data_envio | Mensagens de uma conversa em ordem de envio. |
| `idx_mensagem_ia_conta_data` | `tb_mensagem_ia` | id_conta, data_envio | Histórico da Xepinha do feirante. |
| `idx_pedido_feirante_status` | `tb_pedido` | id_feirante, status_pedido | Tela de vendas do feirante filtrada por situação. |
| `idx_renda_feirante_data` | `tb_renda` | id_feirante, data_renda | Financeiro: lucros do feirante por período (hoje, semana, mês, filtros). |
| `idx_saque_feirante_data` | `tb_saque` | id_feirante, data_solicitacao | Histórico de saques. |
| `idx_xepa_busca` | `tb_xepa` | id_feira, status_xepa, data_retirada | Catálogo: busca as xepas DISPONIVEL de uma feira a partir de hoje sem varrer a tabela. |

**Como as consultas pesadas são tratadas hoje:**
- **Catálogo:** só xepas `DISPONIVEL` com retirada a partir de hoje (`idx_xepa_busca`). Feirante, produto e feira vêm na mesma consulta (`join fetch`), sem uma consulta extra para cada xepa.
- **Financeiro:** filtra por feirante e período (`idx_renda_feirante_data`, `idx_despesa_feirante_data`). O total da despesa é uma coluna calculada e guardada (`valor_despesa`), então não é recalculado a cada leitura.
- **Saque:** a linha do feirante é travada (`SELECT ... FOR UPDATE`) durante o pedido de saque. Assim, dois saques ao mesmo tempo nunca passam do saldo.
- **Venda concorrente:** a coluna `versao` da xepa (controle otimista) recusa a segunda compra da última unidade.

O plano de crescimento (réplicas de leitura, cache, particionamento por região) está em [10-escalabilidade](https://github.com/XepaMais/documentacao/blob/main/10-escalabilidade.md).

---

## 5. Integridade e segurança

- **Chaves estrangeiras** em todos os relacionamentos.
  - `ON DELETE CASCADE` só onde o filho não faz sentido sozinho: dias da feira, itens do carrinho, sessões, imagens, mensagens da IA.
  - Pedidos, pagamentos e rendas **nunca** são apagados em cascata.
- **Regras CHECK:**
  - valores positivos;
  - nota de 1 a 5;
  - horário de fim depois do início;
  - comissão entre 0% e 100% e nunca maior que o total;
  - listas fechadas de situação (`status_xepa`, `status_pedido`, `status_pagamento`...);
  - o chat é sobre um pedido **ou** sobre uma xepa, nunca os dois.
- **Senhas:** guardadas só como hash **PBKDF2-HMAC-SHA256** com 210.000 iterações e sal aleatório.
- **Sessões:** o token não é guardado, só um hash do identificador da sessão. Desconectar um aparelho faz o login dele parar de valer na hora.
- **Pagamentos:** nenhum dado de cartão é guardado, só a forma de pagamento, o valor, a situação e o id da transação.
- **Acesso ao banco:**
  - o MySQL roda no próprio servidor da API e, por padrão, só aceita conexões locais;
  - a API usa um usuário com permissão apenas no `db_xepa`;
  - as credenciais ficam em variáveis de ambiente, fora do Git;
  - a API usa JPA ou consultas parametrizadas; no painel admin, nomes de tabela e coluna só entram no SQL depois de conferidos no `information_schema`.
- **Backup:** snapshots do disco EBS da EC2 (ver 09-tecnologias, seção 3.2).

---

## 6. LGPD no banco

| Dado | Onde | Finalidade |
| --- | --- | --- |
| Nome, e-mail, CPF, telefone, nascimento | `tb_conta` | Criar a conta, identificar e contatar sobre pedidos |
| Dados da banca (CNPJ, CCM, matrícula) | `tb_feirante` | Verificar que o feirante atua regularmente |
| Endereço de entrega | `tb_consumidor` | Entregar pedidos em casa |
| Pedidos, pagamentos, rendas | `tb_pedido`, `tb_pagamento`, `tb_renda` | Executar a compra e cumprir obrigações fiscais |
| Mensagens | `tb_mensagem`, `tb_mensagem_ia` | Comunicação sobre pedidos e respostas da Xepinha |
| Aparelhos conectados | `tb_dispositivo_sessao` | Segurança do acesso |

**Como o banco atende a LGPD:**
- **Consentimento:**
  - `aceite_termos_em` e `versao_termos` registram quando e qual versão dos termos a pessoa aceitou. A API recusa o cadastro sem esse aceite;
  - `aceite_marketing` guarda o consentimento opcional para novidades, que pode ser retirado a qualquer momento.
- **Acesso e portabilidade:** `GET /api/conta/{id}/dados` devolve todos os dados da pessoa em JSON.
- **Eliminação:** `DELETE /api/conta/{id}` **anonimiza** a conta:
  - nome, e-mail, CPF, telefone, foto, endereço e dados da banca são apagados ou trocados por marcadores;
  - `data_exclusao` registra quando isso aconteceu e todas as sessões são encerradas;
  - pedidos e rendas continuam guardados, sem identificar a pessoa, por obrigação fiscal (LGPD, art. 16, I).

Política completa: [11-lgpd](https://github.com/XepaMais/documentacao/blob/main/11-lgpd.md).

---

## 7. Evolução da estrutura

O `01-schema.sql` é a estrutura **atual completa**. Ele foi gerado a partir do script original da equipe somado a todas as mudanças feitas depois.

Quando uma tabela ou coluna nova é necessária:
1. a API cria a mudança sozinha ao iniciar, em [`config/AtualizacaoBanco.java`](https://github.com/XepaMais/backend/blob/main/src/main/java/br/com/xepamais/api/config/AtualizacaoBanco.java). Ela confere no `information_schema` antes, então nunca aplica a mesma mudança duas vezes;
2. a mesma mudança é refletida no `01-schema.sql` e neste dicionário.

Assim o banco de produção é atualizado sem parar o site, e um banco novo já nasce completo.

---

## 8. Dicionário de dados

Tipos, chaves e restrições foram extraídos do `information_schema` do banco validado. As regras `CHECK` aparecem abaixo de cada tabela.
### Contas e acesso

Quem usa o Xepa+ e como entra.


#### `tb_conta`

Dados de acesso e identificação comuns a consumidores e feirantes (uma linha por pessoa).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_conta` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador da conta (é o {idConta} das rotas da API). |
| `nome_conta` | varchar(100) | NOT NULL | Nome completo. |
| `cpf_conta` | char(11) | UNIQUE, NOT NULL | CPF só com dígitos. Único. Após exclusão vira um marcador (X + id). |
| `email_conta` | varchar(100) | UNIQUE, NOT NULL | E-mail de login, em minúsculas. Único. |
| `senha_conta` | varchar(255) | NOT NULL | Hash PBKDF2-HMAC-SHA256 (210.000 iterações, sal aleatório). A senha nunca é guardada nem devolvida. |
| `telefone_conta` | varchar(20) | NULL | Telefone para contato sobre pedidos. |
| `data_nascimento` | date | NULL | Data de nascimento (opcional). |
| `foto_conta` | varchar(255) | NULL | Endereço da foto de perfil (/api/imagens/{id}). |
| `ativo` | tinyint(1) | NOT NULL, padrão `1` | FALSE = conta excluída (soft delete): não entra mais. |
| `data_cadastro` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Quando a conta foi criada. |
| `aceite_termos_em` | datetime | NULL | LGPD: data e hora do aceite dos Termos e da Política de Privacidade. |
| `versao_termos` | varchar(10) | NULL | LGPD: versão dos termos aceita (ex.: 1.0). |
| `aceite_marketing` | tinyint(1) | NOT NULL, padrão `0` | LGPD: consentimento opcional para receber novidades por e-mail (revogável no perfil). |
| `data_exclusao` | datetime | NULL | LGPD: quando a conta foi excluída a pedido do titular (dados anonimizados). |

#### `tb_consumidor`

Perfil de consumidor de uma conta e a forma de recebimento preferida.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_consumidor` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador do consumidor. |
| `id_conta` | int | FK → `tb_conta`, UNIQUE, NOT NULL | Conta dona do perfil (1 para 1). |
| `recebimento_preferido` | varchar(10) | NOT NULL, padrão `RETIRADA` | RETIRADA (na feira) ou ENTREGA (em casa). |
| `cep_entrega` | char(8) | NULL | CEP de entrega (8 dígitos). |
| `logradouro_entrega` | varchar(150) | NULL | Rua/avenida de entrega. |
| `numero_entrega` | varchar(10) | NULL | Número. |
| `complemento_entrega` | varchar(60) | NULL | Complemento (apto, bloco). |
| `bairro_entrega` | varchar(80) | NULL | Bairro. |
| `cidade_entrega` | varchar(80) | NULL | Cidade. |
| `uf_entrega` | char(2) | NULL | Estado (sigla). |

#### `tb_feirante`

Perfil de feirante: dados da banca, registro na Prefeitura e plano contratado.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_feirante` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador do feirante. |
| `id_conta` | int | FK → `tb_conta`, UNIQUE, NOT NULL | Conta dona do perfil (1 para 1). |
| `id_plano` | int | FK → `tb_plano`, NULL | Plano escolhido (Semente, Broto ou Colheita). Define a comissão. |
| `nome_fantasia` | varchar(100) | NOT NULL | Nome da banca mostrado aos consumidores. |
| `cnpj_feirante` | char(14) | UNIQUE, NULL | CNPJ só com dígitos (opcional, único). |
| `ccm_feirante` | varchar(20) | NULL | Cadastro de Contribuintes Mobiliários da Prefeitura. |
| `matricula_feirante` | varchar(20) | UNIQUE, NULL | Matrícula de feirante na Prefeitura (única). |
| `validade_matricula` | varchar(20) | NULL | Validade da matrícula (texto, como aparece no documento). |
| `titular_matricula` | varchar(100) | NULL | Coluna do script original (não usada pela API; ver titular_feirante). |
| `grupo_comercio` | varchar(60) | NULL | Grupo de comércio da matrícula (ex.: Hortifrutícola). |
| `titular_feirante` | varchar(100) | NULL | Titular da matrícula (pode não ser o dono da conta). |

#### `tb_colaborador`

Conta da equipe Xepa+ que cadastra planos (uso administrativo).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_colaborador` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_conta` | int | FK → `tb_conta`, UNIQUE, NOT NULL | Conta do colaborador. |

#### `tb_dispositivo_sessao`

Cada login aberto (um aparelho em "Dispositivos conectados"). Permite desconectar aparelhos.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_dispositivo` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador da sessão (vai dentro do token). |
| `id_conta` | int | FK → `tb_conta` (CASCADE), NOT NULL | Conta logada. |
| `nome_aparelho` | varchar(100) | NULL | Nome amigável (ex.: Windows, Android). |
| `tipo_aparelho` | varchar(12) | NULL | computador, celular ou tablet. |
| `navegador` | varchar(60) | NULL | Navegador (ex.: Chrome, Edge). |
| `token_hash` | char(64) | UNIQUE, NOT NULL | Hash SHA-256 de um identificador aleatório da sessão (o token em si não é guardado). |
| `data_criacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Quando o login foi feito. |
| `expira_em` | datetime | NOT NULL | Validade (30 dias). |
| `ultimo_acesso` | datetime | NULL | Último uso (atualizado no máximo a cada poucos minutos). |
| `revogado` | tinyint(1) | NOT NULL, padrão `0` | TRUE = aparelho desconectado; o token deixa de valer. |

#### `tb_endereco`

Endereços do consumidor (estrutura para vários endereços; hoje a API usa o endereço em tb_consumidor).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_endereco` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_consumidor` | int | FK → `tb_consumidor` (CASCADE), NOT NULL | Dono do endereço. |
| `cep_endereco` | char(8) | NOT NULL | CEP. |
| `logradouro` | varchar(150) | NOT NULL | Rua. |
| `numero_endereco` | varchar(10) | NOT NULL | Número. |
| `complemento` | varchar(60) | NULL | Complemento. |
| `bairro` | varchar(80) | NOT NULL | Bairro. |
| `cidade` | varchar(80) | NOT NULL | Cidade. |
| `uf` | char(2) | NOT NULL | UF. |
| `latitude` | decimal(9,6) | NULL | Latitude (cálculo de frete). |
| `longitude` | decimal(9,6) | NULL | Longitude. |
| `principal` | tinyint(1) | NOT NULL, padrão `0` | Endereço padrão. |

#### `tb_imagem`

Fotos enviadas (perfil, xepas, chat). Ficam no banco para valer em qualquer aparelho.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_imagem` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador (/api/imagens/{id}). |
| `id_conta` | int | FK → `tb_conta` (CASCADE), NOT NULL | Quem enviou. |
| `tipo_conteudo` | varchar(40) | NOT NULL | Tipo MIME (image/jpeg...). |
| `dados_imagem` | mediumblob | NOT NULL | Bytes da imagem (já reduzida no navegador). |
| `data_cadastro` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Data do envio. |

### Feiras e feirantes

Onde e por quem as xepas são vendidas.


#### `tb_plano`

Planos do feirante e a comissão cobrada em cada venda.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_plano` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `codigo_plano` | varchar(20) | UNIQUE, NULL | Código usado pela API e pelo site: gratis, crescer, pro. |
| `id_colaborador` | int | FK → `tb_colaborador`, NULL | Quem cadastrou (opcional). |
| `nome_plano` | varchar(60) | UNIQUE, NOT NULL | Nome mostrado: Semente, Broto, Colheita. |
| `descricao_plano` | text | NULL | Texto do plano. |
| `valor_plano` | decimal(10,2) | NOT NULL, padrão `0.00` | Mensalidade em R$. |
| `percentual_comissao` | decimal(5,2) | NOT NULL, padrão `0.00` | Comissão sobre cada venda (%). |
| `ativo` | tinyint(1) | NOT NULL, padrão `1` | Plano disponível para escolha. |

Regras (CHECK): `(percentual_comissao between 0 and 100)`; `(valor_plano >= 0)`

#### `tb_feira`

Feiras livres (endereço, horário e posição no mapa).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_feira` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `nome_feira` | varchar(100) | NOT NULL | Nome da feira. |
| `endereco_feira` | varchar(150) | NOT NULL | Rua. |
| `numero_feira` | varchar(10) | NULL | Número (ou s/n). |
| `cep_feira` | char(8) | NULL | CEP. |
| `cidade_feira` | varchar(80) | NOT NULL | Cidade. |
| `uf_feira` | char(2) | NOT NULL | UF. |
| `horario_inicio` | time | NULL | Início da feira. |
| `horario_fim` | time | NULL | Fim da feira (deve ser depois do início). |
| `latitude` | decimal(9,6) | NULL | Latitude (mapa e busca por proximidade). |
| `longitude` | decimal(9,6) | NULL | Longitude. |

Regras (CHECK): `(horario_fim > horario_inicio)`

#### `tb_feira_dia`

Dias da semana em que cada feira acontece.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_feira` | int | PK, FK → `tb_feira` (CASCADE), NOT NULL | Feira. |
| `dia_semana` | tinyint | PK, NOT NULL | 1 = segunda ... 7 = domingo. |

Regras (CHECK): `(dia_semana between 1 and 7)`

#### `tb_feirante_feira`

Em quais feiras cada feirante trabalha (N para N).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_feirante` | int | PK, FK → `tb_feirante` (CASCADE), NOT NULL | Feirante. |
| `id_feira` | int | PK, FK → `tb_feira` (CASCADE), NOT NULL | Feira. |

#### `tb_funcionario_feira`

Ajudantes do feirante em cada feira (só o primeiro nome).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_funcionario` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_feirante` | int | FK → `tb_feirante_feira` (CASCADE), NOT NULL | Feirante. |
| `id_feira` | int | FK → `tb_feirante_feira` (CASCADE), NOT NULL | Feira. |
| `nome_funcionario` | varchar(100) | NOT NULL | Nome do ajudante. |

### Ofertas (xepas)

O que está à venda.


#### `tb_categoria`

Categorias das xepas e o peso médio usado no painel de impacto.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_categoria` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `nome_categoria` | varchar(60) | UNIQUE, NOT NULL | Verduras e legumes, Frutas, Tempero, Completa. |
| `peso_medio_kg` | decimal(5,2) | NOT NULL, padrão `2.00` | Peso médio de uma unidade vendida (kg de alimento salvo do desperdício). |

Regras (CHECK): `(peso_medio_kg > 0)`

#### `tb_produto`

Produto que o feirante costuma vender (base de cada xepa).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_produto` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Dono. |
| `id_categoria` | int | FK → `tb_categoria`, NOT NULL | Categoria. |
| `nome_produto` | varchar(100) | NOT NULL | Nome. |
| `descricao_produto` | text | NULL | Descrição. |
| `imagem_produto` | varchar(255) | NULL | Endereço da foto. |
| `unidade_medida` | varchar(10) | NOT NULL | KG, UNIDADE, MACO, DUZIA ou BANDEJA. |
| `preco_referencia` | decimal(10,2) | NULL | Preço cheio (sem desconto). |
| `ativo` | tinyint(1) | NOT NULL, padrão `1` | FALSE = produto removido. |

Regras (CHECK): `(preco_referencia >= 0)`; `(unidade_medida in (\'KG\',\'UNIDADE\',\'MACO\',\'DUZIA\',\'BANDEJA\'))`

#### `tb_xepa`

Oferta de fim de feira: quantidade, preço com desconto e janela de retirada.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_xepa` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_produto` | int | FK → `tb_produto`, NOT NULL | Produto. |
| `id_feira` | int | FK → `tb_feira`, NOT NULL | Feira onde é retirada. |
| `quantidade_xepa` | decimal(10,2) | NOT NULL | Quantidade ainda disponível (não pode ficar negativa). |
| `preco_xepa` | decimal(10,2) | NOT NULL | Preço da xepa (> 0). |
| `validade_xepa` | date | NULL | Consumir até. |
| `itens_xepa` | varchar(255) | NULL | O que vem na xepa. |
| `local_retirada` | varchar(100) | NULL | Onde retirar na feira. |
| `data_retirada` | date | NOT NULL | Dia da retirada. |
| `horario_retirada_inicio` | time | NOT NULL | Início da janela de retirada. |
| `horario_retirada_fim` | time | NOT NULL | Fim da janela (deve ser depois do início). |
| `status_xepa` | varchar(20) | NOT NULL, padrão `DISPONIVEL` | DISPONIVEL, ESGOTADA, EXPIRADA ou CANCELADA. |
| `data_cadastro` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Quando foi publicada. |
| `versao` | int | NOT NULL, padrão `0` | Controle otimista (@Version): impede vender a mesma unidade duas vezes ao mesmo tempo. |

Regras (CHECK): `(horario_retirada_fim > horario_retirada_inicio)`; `(preco_xepa > 0)`; `(quantidade_xepa >= 0)`; `(status_xepa in (\'DISPONIVEL\',\'ESGOTADA\',\'EXPIRADA\',\'CANCELADA\'))`

### Compra e pagamento

Do carrinho ao pedido pago e retirado.


#### `tb_carrinho`

Carrinho do consumidor (um por consumidor, salvo no banco).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_carrinho` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_consumidor` | int | FK → `tb_consumidor` (CASCADE), UNIQUE, NOT NULL | Dono (único). |
| `data_criacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Criação. |

#### `tb_item_carrinho`

Xepas no carrinho.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_item_carrinho` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_carrinho` | int | FK → `tb_carrinho` (CASCADE), NOT NULL | Carrinho. |
| `id_xepa` | int | FK → `tb_xepa` (CASCADE), NOT NULL | Xepa. |
| `quantidade_item` | decimal(10,2) | NOT NULL | Quantidade. |

Únicas compostas: `id_carrinho + id_xepa`<br>Regras (CHECK): `(quantidade_item > 0)`

#### `tb_tipo_pagamento`

Formas de pagamento.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_tipo_pagamento` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `metodo_pagamento` | varchar(40) | UNIQUE, NOT NULL | PIX, CARTAO_CREDITO, CARTAO_DEBITO, DINHEIRO. |

#### `tb_pedido`

Pedido de um consumidor para UM feirante (o checkout divide o carrinho por feirante).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_pedido` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador (o número do pedido é este id com 4 dígitos). |
| `id_consumidor` | int | FK → `tb_consumidor`, NOT NULL | Quem comprou. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Quem vendeu. |
| `data_pedido` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Data e hora. |
| `status_pedido` | varchar(30) | NOT NULL, padrão `AGUARDANDO_PAGAMENTO` | AGUARDANDO_PAGAMENTO, PAGO, PRONTO_RETIRADA, SAIU_PARA_ENTREGA, RETIRADO, ENTREGUE ou CANCELADO. |
| `tipo_recebimento` | varchar(10) | NOT NULL, padrão `RETIRADA` | RETIRADA ou ENTREGA. |
| `valor_total` | decimal(10,2) | NOT NULL | Itens + taxa de entrega. |
| `percentual_comissao` | decimal(5,2) | NOT NULL, padrão `0.00` | Comissão do plano no momento da compra (%). |
| `valor_comissao` | decimal(10,2) | NOT NULL, padrão `0.00` | Comissão do Xepa+ em R$. |
| `codigo_retirada` | char(4) | NULL | Código de 4 dígitos que o consumidor mostra ao feirante. |
| `endereco_entrega` | varchar(255) | NULL | Endereço (só entrega). |
| `taxa_entrega` | decimal(10,2) | NOT NULL, padrão `0.00` | Frete em R$. |

Regras (CHECK): `((percentual_comissao between 0 and 100) and (valor_comissao between 0 and valor_total))`; `(tipo_recebimento in (\'RETIRADA\',\'ENTREGA\'))`; `(status_pedido in (\'AGUARDANDO_PAGAMENTO\',\'PAGO\',\'PRONTO_RETIRADA\',\'RETIRADO\',\'SAIU_PARA_ENTREGA\',\'ENTREGUE\',\'CANCELADO\'))`; `(valor_total >= 0)`

#### `tb_item_pedido`

Itens do pedido com o preço do momento da compra.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_item_pedido` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_pedido` | int | FK → `tb_pedido` (CASCADE), NOT NULL | Pedido. |
| `id_xepa` | int | FK → `tb_xepa`, NOT NULL | Xepa comprada. |
| `quantidade_item` | decimal(10,2) | NOT NULL | Quantidade (> 0). |
| `preco_unitario` | decimal(10,2) | NOT NULL | Preço pago (fica guardado mesmo se a xepa mudar de preço). |

Únicas compostas: `id_pedido + id_xepa`<br>Regras (CHECK): `(preco_unitario >= 0)`; `(quantidade_item > 0)`

#### `tb_pagamento`

Pagamento do pedido. Nenhum dado de cartão é guardado.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_pagamento` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_pedido` | int | FK → `tb_pedido`, NOT NULL | Pedido. |
| `id_tipo_pagamento` | int | FK → `tb_tipo_pagamento`, NOT NULL | Forma de pagamento. |
| `valor_pagamento` | decimal(10,2) | NOT NULL | Valor (> 0). |
| `status_pagamento` | varchar(20) | NOT NULL, padrão `PENDENTE` | PENDENTE, APROVADO, RECUSADO ou ESTORNADO. |
| `id_transacao_gateway` | varchar(100) | NULL | Id da transação no meio de pagamento. |
| `data_criacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Criação. |
| `data_pagamento` | datetime | NULL | Confirmação. |

Regras (CHECK): `(status_pagamento in (\'PENDENTE\',\'APROVADO\',\'RECUSADO\',\'ESTORNADO\'))`; `(valor_pagamento > 0)`

#### `tb_entrega`

Detalhes de entrega em casa (estrutura para integração com logística; hoje o endereço fica em tb_pedido).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_entrega` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_pedido` | int | FK → `tb_pedido` (CASCADE), NOT NULL | Pedido. |
| `id_feira` | int | FK → `tb_feira`, NOT NULL | Feira de origem. |
| `cep_entrega` | char(8) | NOT NULL | CEP. |
| `logradouro` | varchar(150) | NOT NULL | Rua. |
| `numero_entrega` | varchar(10) | NOT NULL | Número. |
| `complemento` | varchar(60) | NULL | Complemento. |
| `bairro` | varchar(80) | NOT NULL | Bairro. |
| `cidade` | varchar(80) | NOT NULL | Cidade. |
| `uf` | char(2) | NOT NULL | UF. |
| `distancia_km` | decimal(5,1) | NOT NULL | Distância da feira. |
| `valor_frete` | decimal(10,2) | NOT NULL | Frete. |
| `tempo_minimo` | smallint | NULL | Prazo mínimo (min). |
| `tempo_maximo` | smallint | NULL | Prazo máximo (min). |
| `id_entrega_gateway` | varchar(100) | NULL | Id no serviço de entrega. |
| `data_entrega` | datetime | NULL | Quando foi entregue. |

Únicas compostas: `id_pedido + id_feira`<br>Regras (CHECK): `(distancia_km >= 0)`; `(valor_frete >= 0)`; `(tempo_maximo >= tempo_minimo)`

#### `tb_avaliacao`

Nota e comentário do consumidor depois de receber o pedido (uma por pedido).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_avaliacao` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_pedido` | int | FK → `tb_pedido`, UNIQUE, NOT NULL | Pedido avaliado (único). |
| `id_consumidor` | int | FK → `tb_consumidor`, NOT NULL | Quem avaliou. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Feirante avaliado. |
| `nota` | tinyint | NOT NULL | 1 a 5 estrelas. |
| `comentario` | text | NULL | Comentário (opcional). |
| `data_avaliacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Data. |

Regras (CHECK): `(nota between 1 and 5)`

### Comunicação

Chat consumidor-feirante, Xepinha (IA) e suporte.


#### `tb_chat`

Conversa entre consumidor e feirante, sobre um pedido OU sobre uma xepa (dúvida antes de comprar).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_chat` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_consumidor` | int | FK → `tb_consumidor`, NOT NULL | Consumidor. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Feirante. |
| `id_pedido` | int | FK → `tb_pedido`, UNIQUE, NULL | Pedido (único; nulo se for dúvida). |
| `id_xepa` | int | FK → `tb_xepa`, NULL | Xepa da dúvida (nulo se for pedido). |
| `status_chat` | varchar(20) | NOT NULL, padrão `RECENTE` | RECENTE ou FINALIZADA. |
| `data_inicio` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Início. |
| `data_finalizacao` | datetime | NULL | Fim. |
| `leitura_consumidor` | datetime | NULL | Última leitura do consumidor (mensagens não lidas). |
| `leitura_feirante` | datetime | NULL | Última leitura do feirante. |

Regras (CHECK): `((id_pedido is null) or (id_xepa is null))`; `(status_chat in (\'RECENTE\',\'FINALIZADA\'))`

#### `tb_mensagem`

Mensagens do chat.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_mensagem` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_chat` | int | FK → `tb_chat` (CASCADE), NOT NULL | Conversa. |
| `id_conta` | int | FK → `tb_conta`, NULL | Autor. |
| `texto_mensagem` | text | NOT NULL | Texto. |
| `data_envio` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Envio. |
| `lida` | tinyint(1) | NOT NULL, padrão `0` | Lida pelo outro lado. |

#### `tb_conversa_ia`

Conversas do feirante com a Xepinha (assistente com IA, planos Broto e Colheita).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_conversa_ia` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_conta` | int | FK → `tb_conta` (CASCADE), NOT NULL | Feirante. |
| `titulo_conversa` | varchar(60) | NOT NULL | Título (primeira pergunta). |
| `data_criacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Criação. |

#### `tb_mensagem_ia`

Perguntas e respostas da Xepinha.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_mensagem_ia` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_conta` | int | FK → `tb_conta` (CASCADE), NOT NULL | Feirante. |
| `id_conversa_ia` | int | FK → `tb_conversa_ia` (CASCADE), NULL | Conversa. |
| `papel` | varchar(10) | NOT NULL | USUARIO ou IA. |
| `texto_mensagem_ia` | text | NOT NULL | Texto. |
| `data_envio` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Envio. |

Regras (CHECK): `(papel in (\'USUARIO\',\'IA\'))`

#### `tb_mensagem_suporte`

Mensagens do formulário de Suporte (com ou sem login).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_mensagem_suporte` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_conta` | int | FK → `tb_conta` (SET NULL), NULL | Conta, se logado (fica nulo se a conta for apagada). |
| `nome_remetente` | varchar(100) | NOT NULL | Nome. |
| `email_remetente` | varchar(100) | NOT NULL | E-mail para resposta. |
| `perfil_remetente` | varchar(12) | NOT NULL | Consumidor, feirante ou visitante. |
| `assunto` | varchar(150) | NOT NULL | Assunto. |
| `mensagem` | text | NOT NULL | Texto. |
| `status_suporte` | varchar(12) | NOT NULL, padrão `ABERTA` | Situação do atendimento. |
| `data_envio` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Envio. |

### Financeiro do feirante

Lucros, gastos e saques.


#### `tb_origem_renda`

Origens de renda (lucro) do feirante.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_origem_renda` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `nome_origem_renda` | varchar(60) | UNIQUE, NOT NULL | Ex.: Venda na feira, Venda de xepa pelo Xepa+ (lançada automaticamente). |

#### `tb_renda`

Entradas de dinheiro do feirante. Vendas pelo app entram sozinhas, já sem a comissão.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_renda` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Feirante. |
| `id_origem_renda` | int | FK → `tb_origem_renda`, NOT NULL | Origem. |
| `id_pedido` | int | FK → `tb_pedido`, UNIQUE, NULL | Pedido que gerou a renda (único; não pode ser editada). |
| `id_feira` | int | FK → `tb_feira` (SET NULL), NULL | Feira. |
| `descricao_renda` | varchar(150) | NOT NULL | Descrição. |
| `valor_renda` | decimal(10,2) | NOT NULL | Valor (> 0). |
| `data_renda` | date | NOT NULL | Data. |
| `data_cadastro` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Lançamento. |

Regras (CHECK): `(valor_renda > 0)`

#### `tb_categoria_despesa`

Categorias de gasto.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_categoria_despesa` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `nome_categoria_despesa` | varchar(80) | UNIQUE, NOT NULL | Nome. |
| `descricao_categoria_despesa` | varchar(150) | NULL | Explicação. |

#### `tb_despesa`

Gastos do feirante.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_despesa` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Feirante. |
| `id_categoria_despesa` | int | FK → `tb_categoria_despesa`, NOT NULL | Categoria. |
| `id_pedido` | int | FK → `tb_pedido`, UNIQUE, NULL | Pedido relacionado (opcional, único). |
| `id_feira` | int | FK → `tb_feira` (SET NULL), NULL | Feira. |
| `descricao_despesa` | varchar(150) | NOT NULL | Descrição. |
| `quantidade_despesa` | decimal(10,2) | NOT NULL, padrão `1.00` | Quantidade (> 0). |
| `valor_unitario` | decimal(10,2) | NOT NULL | Valor unitário (> 0). |
| `valor_despesa` | decimal(10,2) | NULL, calculada | Calculado pelo banco: quantidade x valor unitário (coluna gerada). |
| `data_despesa` | date | NOT NULL | Data. |
| `data_cadastro` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Lançamento. |

Regras (CHECK): `(quantidade_despesa > 0)`; `(valor_unitario > 0)`

#### `tb_saque`

Pedidos de saque via Pix do que o feirante vendeu pelo app (simulado: nenhum dinheiro é transferido).

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_saque` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_feirante` | int | FK → `tb_feirante`, NOT NULL | Feirante. |
| `valor_saque` | decimal(10,2) | NOT NULL | Valor (> 0, nunca acima do saldo). |
| `tipo_chave_pix` | varchar(10) | NOT NULL | CPF, CNPJ, EMAIL, CELULAR ou ALEATORIA. |
| `chave_pix` | varchar(100) | NOT NULL | Chave Pix. |
| `status_saque` | varchar(20) | NOT NULL, padrão `SOLICITADO` | SOLICITADO, CONCLUIDO ou RECUSADO. |
| `id_transacao_gateway` | varchar(100) | NULL | Id da transferência. |
| `data_solicitacao` | datetime | NOT NULL, padrão `CURRENT_TIMESTAMP` | Pedido. |
| `data_conclusao` | datetime | NULL | Conclusão. |

Regras (CHECK): `(status_saque in (\'SOLICITADO\',\'CONCLUIDO\',\'RECUSADO\'))`; `(tipo_chave_pix in (\'CPF\',\'CNPJ\',\'EMAIL\',\'CELULAR\',\'ALEATORIA\'))`; `(valor_saque > 0)`

#### `vw_saldo_feirante`

VIEW: saldo disponível para saque = vendas pelo app − saques não recusados.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_feirante` | int | NOT NULL, padrão `0` | Feirante. |
| `valor_recebido` | decimal(32,2) | NOT NULL, padrão `0.00` | Soma das rendas ligadas a pedidos. |
| `valor_sacado` | decimal(32,2) | NOT NULL, padrão `0.00` | Soma dos saques não recusados. |
| `saldo_disponivel` | decimal(33,2) | NOT NULL, padrão `0.00` | Recebido − sacado. |

### Receitas

Área Cozinha: o que fazer com a xepa.


#### `tb_categoria_receita`

Categorias de receita.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_categoria_receita` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `nome_categoria_receita` | varchar(60) | UNIQUE, NOT NULL | Ex.: Saladas, Sopas. |

#### `tb_receita_culinaria`

Receitas para aproveitar a xepa.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_receita` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `codigo_receita` | varchar(40) | UNIQUE, NULL | Código estável (ex.: salada-caesar). |
| `id_categoria_receita` | int | FK → `tb_categoria_receita`, NULL | Categoria. |
| `titulo_receita` | varchar(120) | NOT NULL | Título. |
| `categoria_receita` | varchar(40) | NULL | Categoria em texto (usada pelo site). |
| `dificuldade_receita` | varchar(20) | NULL | Fácil, Médio... |
| `imagem_receita` | varchar(255) | NULL | Foto. |
| `modo_preparo` | text | NULL | Passo a passo. |
| `tempo_preparo` | int | NULL | Tempo (min). |
| `dificuldade` | varchar(10) | NULL | Coluna do script original (substituída por dificuldade_receita). |

Regras (CHECK): `(dificuldade in (\'FACIL\',\'MEDIA\',\'DIFICIL\'))`; `(tempo_preparo > 0)`

#### `tb_ingrediente_receita`

Ingredientes de cada receita, ligados à categoria de xepa que serve.

| Campo | Tipo | Restrições | Descrição |
| --- | --- | --- | --- |
| `id_ingrediente` | int | PK, NOT NULL, AUTO_INCREMENT | Identificador. |
| `id_receita` | int | FK → `tb_receita_culinaria` (CASCADE), NOT NULL | Receita. |
| `id_categoria` | int | FK → `tb_categoria`, NULL | Categoria de xepa do ingrediente. |
| `nome_ingrediente` | varchar(100) | NOT NULL | Nome. |
| `quantidade_ingrediente` | varchar(50) | NULL | Quantidade (texto livre, ex.: 2 xícaras). |

---

<p align="center"><a href="https://github.com/XepaMais">Xepa+</a> · menos desperdício, mais alimento</p>
