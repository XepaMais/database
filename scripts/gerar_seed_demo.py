"""
Gera ../04-seed-demo.sql e ../05-limpar-demo.sql: dados fictícios que simulam o piloto do Xepa+
na Freguesia do Ó, Brasilândia e Pirituba (São Paulo).

    python scripts/gerar_seed_demo.py

Como os dados são montados:
- Nomes, CPFs, CNPJs e e-mails são inventados. CPF e CNPJ têm dígitos verificadores válidos
  (passam na validação), mas não pertencem a ninguém. Os e-mails usam @demo.xepamais.com.br.
- Todas as contas têm a mesma senha de demonstração (SENHA_DEMO), guardada como hash PBKDF2
  no mesmo formato da API (auth/PasswordHasher.java).
- Preços, quantidades e produtos seguem o que os feirantes contaram na pesquisa de campo
  (documentacao/05-pesquisas.md): sobras de fim de feira vendidas com 40% a 70% de desconto.
- As datas são relativas ao dia em que o script roda no MySQL (CURDATE()/NOW()), então
  o banco sempre tem xepas válidas "hoje" e financeiro preenchido na semana e no mês.
- A semente aleatória é fixa: rodar o gerador de novo produz exatamente o mesmo SQL.
"""
import base64
import hashlib
import random
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

SEMENTE = 2026
SENHA_DEMO = "XepaDemo@2026"
DOMINIO = "demo.xepamais.com.br"
ITERACOES = 210_000
PASTA = Path(__file__).resolve().parent.parent

rnd = random.Random(SEMENTE)


# ---------------------------------------------------------------- utilidades

def q(texto):
    """Texto entre aspas para SQL (escapa aspas simples)."""
    if texto is None:
        return "NULL"
    return "'" + str(texto).replace("\\", "\\\\").replace("'", "''") + "'"


def dinheiro(valor):
    return Decimal(valor).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def hash_senha(senha):
    sal = bytes(rnd.getrandbits(8) for _ in range(16))
    chave = hashlib.pbkdf2_hmac("sha256", senha.encode(), sal, ITERACOES, dklen=32)
    return f"pbkdf2${ITERACOES}${base64.b64encode(sal).decode()}${base64.b64encode(chave).decode()}"


def cpf():
    n = [rnd.randint(0, 9) for _ in range(9)]
    for _ in range(2):
        soma = sum(d * p for d, p in zip(n, range(len(n) + 1, 1, -1)))
        n.append((soma * 10 % 11) % 10)
    return "".join(map(str, n))


def cnpj():
    n = [rnd.randint(0, 9) for _ in range(8)] + [0, 0, 0, 1]
    for pesos in ([5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]):
        resto = sum(d * p for d, p in zip(n, pesos)) % 11
        n.append(0 if resto < 2 else 11 - resto)
    return "".join(map(str, n))


def telefone():
    return f"119{rnd.randint(6000, 9999)}{rnd.randint(1000, 9999)}"


def email(nome):
    base = nome.lower()
    for a, b in zip("áàâãéêíóôõúç", "aaaaeeiooouc"):
        base = base.replace(a, b)
    partes = base.split()
    return f"{partes[0]}.{partes[-1]}@{DOMINIO}"


# ---------------------------------------------------------------- dados

# nome, nome da banca, plano, grupo, feiras (índices de FEIRAS)
FEIRANTES = [
    ("Sebastião Ferreira", "Hortifruti do Tião", "gratis", "Hortifrutícola", [0]),
    ("Rosângela Matos", "Verdes da Rô", "crescer", "Hortifrutícola", [3, 2]),
    ("Antônio Kenji Nakamura", "Sítio Nakamura", "pro", "Hortifrutícola", [4, 5, 2]),
    ("Fabiane Carneiro", "Banca da Fabi", "crescer", "Hortifrutícola", [0, 1]),
    ("Aroaldo Sandes", "Frutas do Aroaldo", "pro", "Frutas", [1, 3]),
    ("Maria das Dores Silva", "Temperos da Dora", "gratis", "Temperos e ervas", [2]),
    ("José Carlos Pereira", "Legumes do Zé", "crescer", "Hortifrutícola", [4]),
    ("Luciana Okabe", "Okabe Orgânicos", "pro", "Orgânicos", [5, 6]),
    ("Raimundo Nonato Souza", "Bananas do Nonato", "gratis", "Frutas", [6, 7]),
    ("Cícera Albuquerque", "Quitanda da Cícera", "crescer", "Hortifrutícola", [8, 0]),
]

FEIRAS = [
    "Feira da Vila Brasilândia",
    "Feira da Rua Laranjeiras do Sul",
    "Feira da Freguesia do Ó - Bruno Bertucci",
    "Feira da Freguesia do Ó - Chico de Paula",
    "Feira de Pirituba - Rua Jurubim",
    "Feira de Pirituba - Av. do Anastácio",
    "Feira Livre da Lapa",
    "Feira de Pinheiros",
    "Feira Xepa Central",
]

# nome, categoria, unidade, preço cheio, itens, foto
PRODUTOS = [
    ("Xepa de legumes", "Verduras e legumes", "BANDEJA", 30, "Abobrinha, chuchu, cenoura, beterraba e vagem", "legumesFeira.jpg"),
    ("Kit tomate e cebola", "Verduras e legumes", "KG", 9, "Tomate italiano, cebola e pimentão", "tomateCebola.jpg"),
    ("Penca de banana nanica", "Frutas", "DUZIA", 8, "Banana nanica bem madura, ótima para vitamina e bolo", "bananas.jpg"),
    ("Maço de coentro", "Tempero", "MACO", 4, "Coentro fresco colhido na véspera", "coentro.jpg"),
    ("Legumes sortidos", "Verduras e legumes", "BANDEJA", 25, "Batata, cenoura, mandioquinha e abóbora", "legumesSortidos.jpg"),
    ("Folhas para salada", "Verduras e legumes", "BANDEJA", 18, "Alface crespa, alface roxa, rúcula e agrião", "alface.jpg"),
    ("Abóbora cabotiá", "Verduras e legumes", "KG", 6, "Abóbora cabotiá em pedaços", "abobora.jpg"),
    ("Caixinha de morango", "Frutas", "BANDEJA", 12, "Morango bem vermelho, consumir em até 2 dias", "morangos.jpg"),
    ("Maço de manjericão", "Tempero", "MACO", 5, "Manjericão de folha larga", "manjericao.jpg"),
    ("Brócolis e couve-flor", "Verduras e legumes", "UNIDADE", 10, "Uma cabeça de cada", "brocolisCouveFlor.jpg"),
    ("Frutas tropicais", "Frutas", "BANDEJA", 28, "Mamão, manga, abacaxi e maracujá", "frutasTropicais.jpg"),
    ("Cesta completa da xepa", "Completa", "UNIDADE", 45, "Legumes, frutas e temperos do fim da feira", "cestaLegumes.jpg"),
    ("Tomate para molho", "Verduras e legumes", "KG", 8, "Tomate bem maduro, perfeito para molho", "tomates.jpg"),
    ("Alface crespa", "Verduras e legumes", "UNIDADE", 4, "Pé de alface crespa", "alfaceCrespa.jpg"),
    ("Gengibre", "Tempero", "KG", 22, "Gengibre fresco", "gengibre.jpg"),
]

NOMES_CONSUMIDORES = [
    "Henrique Mazza", "Ana Beatriz Lima", "Carlos Eduardo Rocha", "Juliana Prado", "Marcos Vinícius Teles",
    "Patrícia Gomes", "Rafael Nogueira", "Camila Duarte", "Thiago Moreira", "Larissa Fontes",
    "Bruno Cardoso", "Fernanda Alves", "Gustavo Henrique Reis", "Beatriz Campos", "Lucas Martins",
    "Aline Barbosa", "Diego Ramos", "Vanessa Ribeiro", "Pedro Henrique Castro", "Mariana Lopes",
    "Felipe Araújo", "Natália Vieira", "Rodrigo Cunha", "Isabela Moura", "André Luiz Batista",
    "Gabriela Rezende", "Eduardo Peixoto", "Renata Farias", "Leonardo Santana", "Tatiane Correia",
]

RUAS = [
    ("Avenida Itaberaba", "Freguesia do Ó", "02734000"), ("Rua Parapuã", "Vila Brasilândia", "02831000"),
    ("Avenida Inajar de Souza", "Vila Nova Cachoeirinha", "02717000"), ("Rua Jurubim", "Pirituba", "05159200"),
    ("Avenida Deputado Cantídio Sampaio", "Vila Brasilândia", "02860000"), ("Rua Bonifácio Cubas", "Freguesia do Ó", "02731000"),
    ("Avenida Mutinga", "Pirituba", "05110000"), ("Rua Alfredo Pujol", "Santana", "02017010"),
]

COMENTARIOS_BONS = [
    "Legumes ótimos, deu para fazer sopa a semana toda.", "Muito barato e bem fresco. Volto a comprar!",
    "Retirada rápida, feirante muito atencioso.", "As frutas estavam maduras no ponto, adorei.",
    "Melhor custo-benefício da feira.", "Cesta bem servida, veio mais do que eu esperava.",
]
COMENTARIOS_MEDIOS = [
    "Bom, mas algumas folhas estavam murchas.", "Gostei, só demorou um pouco para separar.",
]
MENSAGENS = [
    ("consumidor", "Oi! Posso retirar às 13h?"), ("feirante", "Pode sim, estou na barraca até 13h30."),
    ("consumidor", "Combinado, obrigado!"), ("feirante", "Seu pedido já está separado."),
    ("consumidor", "Tem sacola aí ou levo a minha?"), ("feirante", "Temos sacola, pode vir tranquilo."),
]


# ---------------------------------------------------------------- geração

def gerar():
    sql = []
    w = sql.append
    w("""-- =====================================================================
-- Xepa+ | 04-seed-demo.sql   (GERADO por scripts/gerar_seed_demo.py, não edite à mão)
-- Dados FICTÍCIOS que simulam o piloto do Xepa+ na Freguesia do Ó, Brasilândia
-- e Pirituba: 10 feirantes, 30 consumidores, produtos, xepas, pedidos, pagamentos,
-- financeiro, conversas e avaliações.
--
-- Pré-requisitos: 01-schema.sql, 02-seed-base.sql e 03-seed-feiras.sql.
-- Contas: <nome.sobrenome>@demo.xepamais.com.br, senha de todas: %s
-- Datas relativas a hoje (CURDATE/NOW). Para apagar estes dados: 05-limpar-demo.sql
-- =====================================================================
USE db_xepa;
SET NAMES utf8mb4;
START TRANSACTION;
""" % SENHA_DEMO)

    planos = {"gratis": Decimal("15.00"), "crescer": Decimal("8.00"), "pro": Decimal("5.00")}

    # ---- feirantes
    w("\n-- ---------- Feirantes ----------")
    for i, (nome, banca, plano, grupo, feiras) in enumerate(FEIRANTES, 1):
        mail = email(nome)
        dias = rnd.randint(60, 240)
        w(f"INSERT INTO tb_conta (nome_conta, cpf_conta, email_conta, senha_conta, telefone_conta, data_nascimento, ativo, data_cadastro, aceite_termos_em, versao_termos, aceite_marketing) "
          f"VALUES ({q(nome)}, {q(cpf())}, {q(mail)}, {q(hash_senha(SENHA_DEMO))}, {q(telefone())}, "
          f"'{rnd.randint(1960, 1995)}-{rnd.randint(1, 12):02d}-{rnd.randint(1, 28):02d}', TRUE, NOW() - INTERVAL {dias} DAY, NOW() - INTERVAL {dias} DAY, '1.0', {rnd.choice(['TRUE', 'FALSE'])});")
        w(f"SET @conta_f{i} = LAST_INSERT_ID();")
        matricula = f"{rnd.randint(1, 99):03d}.{rnd.randint(100, 999)}-{rnd.randint(0, 9)}"
        doc = q(cnpj()) if plano != "gratis" else "NULL"
        w(f"INSERT INTO tb_feirante (id_conta, id_plano, nome_fantasia, cnpj_feirante, ccm_feirante, matricula_feirante, validade_matricula, titular_feirante, grupo_comercio) "
          f"VALUES (@conta_f{i}, (SELECT id_plano FROM tb_plano WHERE codigo_plano = {q(plano)}), {q(banca)}, {doc}, "
          f"{q(f'{rnd.randint(1, 9)}.{rnd.randint(100, 999)}.{rnd.randint(100, 999)}-{rnd.randint(0, 9)}') if plano != 'gratis' else 'NULL'}, "
          f"{q(matricula)}, {q(f'{rnd.randint(1, 28):02d}/{rnd.randint(1, 12):02d}/2027')}, {q(nome)}, {q(grupo)});")
        w(f"SET @f{i} = LAST_INSERT_ID();")
        for fe in feiras:
            w(f"INSERT INTO tb_feirante_feira (id_feirante, id_feira) SELECT @f{i}, id_feira FROM tb_feira WHERE nome_feira = {q(FEIRAS[fe])};")

    # ---- consumidores
    w("\n-- ---------- Consumidores ----------")
    for i, nome in enumerate(NOMES_CONSUMIDORES, 1):
        dias = rnd.randint(5, 180)
        w(f"INSERT INTO tb_conta (nome_conta, cpf_conta, email_conta, senha_conta, telefone_conta, data_nascimento, ativo, data_cadastro, aceite_termos_em, versao_termos, aceite_marketing) "
          f"VALUES ({q(nome)}, {q(cpf())}, {q(email(nome))}, {q(hash_senha(SENHA_DEMO))}, {q(telefone())}, "
          f"'{rnd.randint(1955, 2005)}-{rnd.randint(1, 12):02d}-{rnd.randint(1, 28):02d}', TRUE, NOW() - INTERVAL {dias} DAY, NOW() - INTERVAL {dias} DAY, '1.0', {rnd.choice(['TRUE', 'FALSE', 'FALSE'])});")
        rua, bairro, cep = rnd.choice(RUAS)
        entrega = rnd.random() < 0.3
        w(f"INSERT INTO tb_consumidor (id_conta, recebimento_preferido, cep_entrega, logradouro_entrega, numero_entrega, bairro_entrega, cidade_entrega, uf_entrega) "
          f"VALUES (LAST_INSERT_ID(), {q('ENTREGA' if entrega else 'RETIRADA')}, {q(cep)}, {q(rua)}, {q(str(rnd.randint(10, 2500)))}, {q(bairro)}, 'São Paulo', 'SP');")
        w(f"SET @c{i} = LAST_INSERT_ID(); SET @conta_c{i} = (SELECT id_conta FROM tb_consumidor WHERE id_consumidor = @c{i});")

    # ---- produtos e xepas
    w("\n-- ---------- Produtos e xepas (ofertas) ----------")
    xepas = []  # (variavel, feirante, preco, produto, unidade)
    nx = 0
    for i, (_, _, _, grupo, feiras) in enumerate(FEIRANTES, 1):
        escolhidos = rnd.sample(PRODUTOS, 4)
        for nome, cat, un, cheio, itens, foto in escolhidos:
            w(f"INSERT INTO tb_produto (id_feirante, id_categoria, nome_produto, descricao_produto, imagem_produto, unidade_medida, preco_referencia, ativo) "
              f"VALUES (@f{i}, (SELECT id_categoria FROM tb_categoria WHERE nome_categoria = {q(cat)}), {q(nome)}, {q(itens)}, {q('/imagens/xepas/' + foto)}, {q(un)}, {cheio:.2f}, TRUE);")
            w("SET @prod = LAST_INSERT_ID();")
            for _ in range(rnd.choice([1, 2])):
                if nx >= 60:
                    break
                nx += 1
                preco = dinheiro(cheio * rnd.uniform(0.3, 0.6))
                if preco <= 0:
                    preco = Decimal("1.00")
                # Situação: a maioria à venda hoje; algumas esgotadas, vencidas ou canceladas.
                sorteio = rnd.random()
                if sorteio < 0.6:
                    status, dia, qtd = "DISPONIVEL", rnd.randint(0, 2), rnd.randint(2, 12)
                elif sorteio < 0.82:
                    status, dia, qtd = "ESGOTADA", -rnd.randint(1, 20), 0
                elif sorteio < 0.94:
                    status, dia, qtd = "EXPIRADA", -rnd.randint(3, 30), rnd.randint(1, 4)
                else:
                    status, dia, qtd = "CANCELADA", -rnd.randint(1, 10), rnd.randint(1, 4)
                feira = FEIRAS[rnd.choice(feiras)]
                ini = rnd.choice(["12:00", "12:30", "13:00"])
                fim = {"12:00": "13:30", "12:30": "14:00", "13:00": "14:30"}[ini]
                data = f"CURDATE() + INTERVAL {dia} DAY"
                w(f"INSERT INTO tb_xepa (id_produto, id_feira, quantidade_xepa, preco_xepa, validade_xepa, itens_xepa, local_retirada, data_retirada, horario_retirada_inicio, horario_retirada_fim, status_xepa, data_cadastro, versao) "
                  f"VALUES (@prod, (SELECT id_feira FROM tb_feira WHERE nome_feira = {q(feira)}), {qtd}, {preco}, {data} + INTERVAL 2 DAY, {q(itens)}, 'Na barraca, fim da feira', {data}, '{ini}', '{fim}', {q(status)}, NOW() - INTERVAL {max(0, -dia) + rnd.randint(0, 1)} DAY, 0);")
                w(f"SET @x{nx} = LAST_INSERT_ID(); SET @feira_x{nx} = (SELECT id_feira FROM tb_xepa WHERE id_xepa = @x{nx});")
                xepas.append((f"@x{nx}", i, preco, nome, status))

    # ---- pedidos
    w("\n-- ---------- Pedidos, itens, pagamentos, renda do feirante e conversas ----------")
    situacoes = (["RETIRADO"] * 20 + ["ENTREGUE"] * 4 + ["PAGO"] * 6 + ["PRONTO_RETIRADA"] * 4
                 + ["CANCELADO"] * 4 + ["SAIU_PARA_ENTREGA"] * 2)
    rnd.shuffle(situacoes)
    pagamentos = ["PIX"] * 6 + ["CARTAO_CREDITO"] * 2 + ["CARTAO_DEBITO"]
    rendas_xepa = {i: Decimal("0") for i in range(1, len(FEIRANTES) + 1)}
    for p, situacao in enumerate(situacoes, 1):
        c = rnd.randint(1, len(NOMES_CONSUMIDORES))
        concluido = situacao in ("RETIRADO", "ENTREGUE", "CANCELADO")
        dias = rnd.randint(1, 45) if concluido else 0
        # Itens do mesmo feirante (um pedido por feirante, como no checkout da API).
        candidatas = [x for x in xepas if x[4] in (("DISPONIVEL",) if not concluido else ("ESGOTADA", "DISPONIVEL", "EXPIRADA"))]
        primeira = rnd.choice(candidatas)
        f = primeira[1]
        do_feirante = [x for x in candidatas if x[1] == f]
        itens = rnd.sample(do_feirante, min(len(do_feirante), rnd.randint(1, 2)))
        qtds = [rnd.randint(1, 3) for _ in itens]
        subtotal = sum((x[2] * qq for x, qq in zip(itens, qtds)), Decimal("0"))
        entrega = situacao in ("ENTREGUE", "SAIU_PARA_ENTREGA")
        taxa = Decimal("6.00") if entrega else Decimal("0.00")
        total = subtotal + taxa
        perc = planos[FEIRANTES[f - 1][2]]
        comissao = dinheiro(subtotal * perc / 100)
        quando = f"NOW() - INTERVAL {dias} DAY - INTERVAL {rnd.randint(0, 600)} MINUTE"
        endereco = "NULL"
        if entrega:
            rua, bairro, cep = rnd.choice(RUAS)
            endereco = q(f"{rua}, {rnd.randint(10, 2500)} - {bairro}, São Paulo/SP - CEP {cep[:5]}-{cep[5:]}")
        w(f"INSERT INTO tb_pedido (id_consumidor, id_feirante, data_pedido, status_pedido, tipo_recebimento, valor_total, percentual_comissao, valor_comissao, codigo_retirada, endereco_entrega, taxa_entrega) "
          f"VALUES (@c{c}, @f{f}, {quando}, {q(situacao)}, {q('ENTREGA' if entrega else 'RETIRADA')}, {total}, {perc}, {comissao}, '{rnd.randint(1000, 9999)}', {endereco}, {taxa});")
        w("SET @p = LAST_INSERT_ID(); SET @data_p = (SELECT data_pedido FROM tb_pedido WHERE id_pedido = @p);")
        descricao = []
        for (var, _, preco, nome, _), qq in zip(itens, qtds):
            w(f"INSERT INTO tb_item_pedido (id_pedido, id_xepa, quantidade_item, preco_unitario) VALUES (@p, {var}, {qq}, {preco});")
            descricao.append(f"{qq}x {nome}")
        status_pag = "ESTORNADO" if situacao == "CANCELADO" else "APROVADO"
        w(f"INSERT INTO tb_pagamento (id_pedido, id_tipo_pagamento, valor_pagamento, status_pagamento, id_transacao_gateway, data_criacao, data_pagamento) "
          f"VALUES (@p, (SELECT id_tipo_pagamento FROM tb_tipo_pagamento WHERE metodo_pagamento = {q(rnd.choice(pagamentos))}), {total}, {q(status_pag)}, {q(f'demo-{SEMENTE}-{p:04d}')}, @data_p, @data_p);")
        if situacao != "CANCELADO":
            liquido = total - comissao
            rendas_xepa[f] += liquido
            # Mesmo texto que a API grava: "Pedido nº 0042 - 2x Kit sopa, 1x ..."
            w(f"INSERT INTO tb_renda (id_feirante, id_origem_renda, id_pedido, id_feira, descricao_renda, valor_renda, data_renda, data_cadastro) "
              f"VALUES (@f{f}, (SELECT id_origem_renda FROM tb_origem_renda WHERE nome_origem_renda = 'Venda de xepa pelo Xepa+'), @p, @feira_{itens[0][0][1:]}, "
              f"LEFT(CONCAT('Pedido nº ', LPAD(@p, 4, '0'), ' - ', {q(', '.join(descricao))}), 150), {liquido}, DATE(@data_p), @data_p);")
        # Conversa do pedido (como a API cria no checkout).
        finalizada = concluido
        w(f"INSERT INTO tb_chat (id_consumidor, id_feirante, id_pedido, status_chat, data_inicio, data_finalizacao, leitura_consumidor, leitura_feirante) "
          f"VALUES (@c{c}, @f{f}, @p, {q('FINALIZADA' if finalizada else 'RECENTE')}, @data_p, {'@data_p + INTERVAL 3 HOUR' if finalizada else 'NULL'}, @data_p + INTERVAL 1 HOUR, {'@data_p + INTERVAL 1 HOUR' if finalizada or rnd.random() < 0.5 else 'NULL'});")
        if rnd.random() < 0.6:
            w("SET @chat = LAST_INSERT_ID();")
            inicio = rnd.randrange(0, len(MENSAGENS) - 1, 2)
            for k, (autor, texto) in enumerate(MENSAGENS[inicio:inicio + rnd.choice([2, 3])]):
                conta = f"@conta_c{c}" if autor == "consumidor" else f"@conta_f{f}"
                w(f"INSERT INTO tb_mensagem (id_chat, id_conta, texto_mensagem, data_envio, lida) VALUES (@chat, {conta}, {q(texto)}, @data_p + INTERVAL {10 + 7 * k} MINUTE, {'TRUE' if finalizada else 'FALSE'});")
        # Avaliação de parte dos pedidos concluídos.
        if situacao in ("RETIRADO", "ENTREGUE") and rnd.random() < 0.7:
            nota = rnd.choices([5, 4, 3], weights=[6, 3, 1])[0]
            comentario = rnd.choice(COMENTARIOS_BONS if nota >= 4 else COMENTARIOS_MEDIOS)
            w(f"INSERT INTO tb_avaliacao (id_pedido, id_consumidor, id_feirante, nota, comentario, data_avaliacao) VALUES (@p, @c{c}, @f{f}, {nota}, {q(comentario)}, @data_p + INTERVAL 1 DAY);")

    # ---- financeiro além do app: vendas na feira, despesas e saques
    w("\n-- ---------- Financeiro do feirante: vendas na feira, despesas e saques ----------")
    despesas = [
        ("Mercadoria", "Compra no Ceagesp", 1, (180, 650)), ("Transporte", "Frete até a feira", 1, (40, 90)),
        ("Combustível", "Gasolina da Kombi", 1, (80, 200)), ("Embalagens e sacolas", "Sacolas e bandejas", 2, (15, 40)),
        ("Ajudantes/funcionários", "Diária do ajudante", 1, (80, 120)), ("Taxas e licenças", "Taxa da feira", 1, (30, 60)),
        ("Alimentação", "Almoço na feira", 2, (18, 30)),
    ]
    for i, (_, _, plano, _, feiras) in enumerate(FEIRANTES, 1):
        feira = f"(SELECT id_feira FROM tb_feira WHERE nome_feira = {q(FEIRAS[feiras[0]])})"
        for _ in range(8):
            valor = dinheiro(rnd.uniform(250, 1300))
            w(f"INSERT INTO tb_renda (id_feirante, id_origem_renda, id_feira, descricao_renda, valor_renda, data_renda) VALUES (@f{i}, "
              f"(SELECT id_origem_renda FROM tb_origem_renda WHERE nome_origem_renda = 'Venda na feira'), {feira}, 'Vendas do dia na barraca', {valor}, CURDATE() - INTERVAL {rnd.randint(0, 40)} DAY);")
        for cat, desc, qtd, (a, b) in rnd.sample(despesas, 6):
            # valor_despesa é calculado pelo banco (quantidade x valor unitário).
            w(f"INSERT INTO tb_despesa (id_feirante, id_categoria_despesa, id_feira, descricao_despesa, quantidade_despesa, valor_unitario, data_despesa) VALUES (@f{i}, "
              f"(SELECT id_categoria_despesa FROM tb_categoria_despesa WHERE nome_categoria_despesa = {q(cat)}), {feira}, {q(desc)}, {qtd}, {dinheiro(rnd.uniform(a, b))}, CURDATE() - INTERVAL {rnd.randint(0, 40)} DAY);")
        # Saque: no máximo metade do que entrou pelo app (o saldo nunca fica negativo).
        saldo = rendas_xepa[i]
        if saldo >= 20:
            valor = dinheiro(saldo * Decimal(rnd.uniform(0.3, 0.5)))
            status = rnd.choice(["CONCLUIDO", "CONCLUIDO", "SOLICITADO"])
            w(f"INSERT INTO tb_saque (id_feirante, valor_saque, tipo_chave_pix, chave_pix, status_saque, data_solicitacao, data_conclusao) VALUES (@f{i}, {valor}, 'EMAIL', "
              f"(SELECT email_conta FROM tb_conta WHERE id_conta = @conta_f{i}), {q(status)}, NOW() - INTERVAL 3 DAY, {'NOW() - INTERVAL 2 DAY' if status == 'CONCLUIDO' else 'NULL'});")

    w("\nCOMMIT;\n")
    w("-- Conferência rápida")
    w("SELECT 'contas demo' AS item, COUNT(*) AS total FROM tb_conta WHERE email_conta LIKE '%@demo.xepamais.com.br'\n"
      "UNION ALL SELECT 'xepas à venda hoje', COUNT(*) FROM tb_xepa WHERE status_xepa = 'DISPONIVEL' AND data_retirada >= CURDATE()\n"
      "UNION ALL SELECT 'pedidos', COUNT(*) FROM tb_pedido\nUNION ALL SELECT 'avaliações', COUNT(*) FROM tb_avaliacao;")
    return "\n".join(sql) + "\n"


LIMPAR = """-- =====================================================================
-- Xepa+ | 05-limpar-demo.sql   (GERADO por scripts/gerar_seed_demo.py)
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
DELETE FROM tb_feirante_feira WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_feirante WHERE id_feirante IN (SELECT id_feirante FROM demo_feirante);
DELETE FROM tb_item_carrinho WHERE id_carrinho IN (SELECT id_carrinho FROM tb_carrinho WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor));
DELETE FROM tb_carrinho WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);
DELETE FROM tb_consumidor WHERE id_consumidor IN (SELECT id_consumidor FROM demo_consumidor);
DELETE FROM tb_dispositivo_sessao WHERE id_conta IN (SELECT id_conta FROM demo_conta);
DELETE FROM tb_conta WHERE id_conta IN (SELECT id_conta FROM demo_conta);

COMMIT;
"""

if __name__ == "__main__":
    (PASTA / "04-seed-demo.sql").write_text(gerar(), encoding="utf-8", newline="\n")
    (PASTA / "05-limpar-demo.sql").write_text(LIMPAR, encoding="utf-8", newline="\n")
    print("Gerados 04-seed-demo.sql e 05-limpar-demo.sql")
