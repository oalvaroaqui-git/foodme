# Plano de Implementação: Persistência em PostgreSQL

**Spec**: [spec.md](spec.md)
**Criado**: 2026-07-11
**Depende de**: spec 001 implementada (substitui o `OrderStorage` de ficheiro
JSON mantendo o mesmo contrato de API)

## Contexto técnico

- **Linguagem/runtime**: Node.js >=22.16.0, Express 4.x (existente)
- **Dependências novas**: `pg` (node-postgres) — driver oficial mínimo, sem
  ORM (Artigo I; justificação no Complexity Tracking)
- **Armazenamento**: PostgreSQL 16; tabela `orders` com colunas tipadas para
  os campos consultáveis e `jsonb` para os itens; esquema aplicado de forma
  idempotente no arranque (`CREATE TABLE IF NOT EXISTS`)
- **Ambiente local**: `docker-compose.yml` com `postgres:16-alpine`,
  healthcheck e volume nomeado (RF-006 da spec)
- **Configuração**: `DATABASE_URL` lida do ambiente — o `npm start` já usa
  `--env-file=.env` (Artigo V); `.env.example` versionado como documentação
- **Observabilidade** (Artigo II): mantém os eventos de negócio da spec 001
  (`order_created`, `order_not_found`, `orders_anonymized`) e acrescenta os
  eventos de infraestrutura:
  - `db_connected` — no arranque, com host e base de dados (sem credenciais)
  - `db_unavailable` — falha de ligação/query, com o motivo
  - `db_query` (nível debug) — texto da query e duração em ms, base para os
    exercícios de observabilidade de latência

## Verificação da Constituição

| Artigo | Cumpre? | Justificação (se não) |
|--------|---------|------------------------|
| I — Simplicidade | ❌ | Nova dependência `pg` + serviço externo — ver Complexity Tracking |
| II — Observabilidade | ✅ | Eventos de negócio mantidos + eventos de infraestrutura de BD |
| III — API consistente | ✅ | Contrato inalterado (RF-002); reutiliza `contracts/order-api.yaml` da spec 001 |
| IV — Testável por contrato | ✅ | Os testes de contrato da spec 001 passam sem alteração sobre o novo armazenamento |
| V — Sem segredos | ✅ | `DATABASE_URL` só em `.env` (não versionado); `.env.example` sem credenciais reais |

## Estrutura / ficheiros afetados

```
docker-compose.yml        # NOVO — postgres:16-alpine para desenvolvimento local
.env.example              # NOVO — documenta DATABASE_URL (sem segredos reais)
server/
├── db.js                 # NOVO — pool `pg`, aplicação idempotente do esquema,
│                         #        helper de query com log de duração (Artigo II)
├── db/
│   └── schema.sql        # NOVO — CREATE TABLE IF NOT EXISTS orders (...)
├── orders.js             # ALTERADO — OrderStorage passa a SQL (add/getById/
│                         #            anonimização); importação única do orders.json
└── index.js              # ALTERADO — arranque aguarda ligação à BD; 503 quando
                          #            a BD está indisponível em runtime
```

## Decisões de desenho

1. **Driver puro, sem ORM**: o projeto tem uma entidade e três queries; um ORM
   acrescentaria mais conceitos do que os que elimina (Artigo I).
2. **Esquema no arranque, não migrações**: um único `schema.sql` idempotente
   cobre RF-003; ferramentas de migração ficam explicitamente fora de âmbito
   até haver segunda alteração de esquema.
3. **Tabela `orders`**: colunas tipadas (`id uuid PK`, `created_at timestamptz`,
   `restaurant_id`, `restaurant_name`, `payment_method`, `total numeric(10,2)`)
   e `jsonb` para `items` e `deliver_to` — consultável por id e data, flexível
   nos itens. Detalhe em [data-model.md](data-model.md).
4. **Anonimização em SQL** (RF-004): um único
   `UPDATE orders SET deliver_to = NULL WHERE created_at < now() - interval '30 days' AND deliver_to IS NOT NULL`,
   no arranque e a cada 24 h — mais simples e atómico do que iterar em Node.
5. **Importação única** (RF-007): no arranque, se `server/data/orders.json`
   existir, insere com `ON CONFLICT (id) DO NOTHING` e renomeia o ficheiro para
   `orders.json.imported` — idempotente por construção.
6. **Falhas de BD**: no arranque, sem ligação → processo termina com
   `db_unavailable` (caso extremo da spec); em runtime, erro de query →
   `503 {error}` e o pool reconecta sozinho.

## Fases

### Fase 0 — Investigação (research.md)
Resolvida — ver [research.md](research.md): driver vs ORM, estratégia de
esquema e execução local via Docker.

### Fase 1 — Desenho
- [data-model.md](data-model.md) — tabela `orders` e mapeamento da entidade
  da spec 001
- Contratos: **inalterados** — reutiliza
  [../001-persistencia-pedidos/contracts/order-api.yaml](../001-persistencia-pedidos/contracts/order-api.yaml) (RF-002)
- [quickstart.md](quickstart.md) — validação manual com Docker + psql

### Fase 2 — Decomposição em tarefas (tasks.md)
Ver [tasks.md](tasks.md). Ordenação: infraestrutura local → módulo de BD →
storage → resiliência → importação → instrumentação → validação. Os testes de
contrato da spec 001 correm contra o novo storage antes da troca ser dada por
concluída.

## Complexity Tracking

**Exceção ao Artigo I** — nova dependência `pg` e novo serviço (PostgreSQL):
o ficheiro JSON não oferece escrita concorrente segura nem integridade
transacional (limitações registadas na spec), e a base de dados passa a ser
alvo dos exercícios de observabilidade que são o propósito deste projeto.
Mitigação: driver oficial único (sem ORM, sem ferramenta de migrações), esquema
de uma tabela, e Docker Compose para que o custo de setup local seja um comando.
