# Tarefas: Persistência em PostgreSQL

**Plano**: [plan.md](plan.md)
**Pré-requisito**: tarefas da spec 001 concluídas (T001–T012) — esta spec
substitui o armazenamento do `OrderStorage` mantendo o contrato da API.

Convenções: `[P]` = paralelizável (ficheiros independentes).
Cada tarefa indica o(s) ficheiro(s) exato(s) que toca.

## Fase A — Fundações (infraestrutura local e módulo de BD)

- [ ] T001 [P] Criar `docker-compose.yml`: serviço `db` com
      `postgres:16-alpine`, `POSTGRES_USER/DB=foodme`, healthcheck
      `pg_isready`, volume nomeado `foodme-pgdata`, porta 5432 —
      `docker-compose.yml`
- [ ] T002 [P] Criar `.env.example` com
      `DATABASE_URL=postgres://foodme:foodme@localhost:5432/foodme` e
      confirmar que `.env` está no `.gitignore` (Artigo V) — `.env.example`,
      `.gitignore`
- [ ] T003 Adicionar a dependência `pg` (exceção ao Artigo I justificada no
      plano) — `package.json`
- [ ] T004 [P] Criar o esquema idempotente: tabela `orders` conforme
      [data-model.md](data-model.md) (`CREATE TABLE IF NOT EXISTS` + índice
      parcial `idx_orders_anonymize`) — `server/db/schema.sql`
- [ ] T005 Criar módulo de BD: `pg.Pool` a partir de `DATABASE_URL`, aplicação
      do `schema.sql` no arranque, helper `query()` que loga `db_query`
      (texto + duração ms, nível debug) e eventos `db_connected` /
      `db_unavailable` (RF-003; Artigo II) — `server/db.js`

## Fase B — Testes de contrato (antes da implementação)

O contrato é o da spec 001
([../001-persistencia-pedidos/contracts/order-api.yaml](../001-persistencia-pedidos/contracts/order-api.yaml));
os testes existentes devem passar sem alteração sobre o novo storage (RF-002).

- [ ] T006 Preparar os testes de contrato da spec 001 para correr contra o
      PostgreSQL: `DATABASE_URL` de teste e `TRUNCATE orders` entre execuções
      (setup/teardown), sem alterar as asserções — `test/order-api.test.js`
- [ ] T007 [P] Teste do storage: inserir e obter por id preserva tipos
      (`total` numérico com 2 casas, `items` como array); anonimização zera
      `deliver_to` apenas de pedidos com mais de 30 dias —
      `test/order-storage.test.js`

## Fase C — Implementação

- [ ] T008 Reimplementar `OrderStorage` sobre SQL: `add()` com `INSERT`,
      `getById()` com `SELECT` e conversão `snake_case` → `camelCase`
      (RF-001, RF-002) — `server/orders.js`
- [ ] T009 Substituir a rotina de anonimização pelo `UPDATE` único de
      [data-model.md](data-model.md), no arranque e a cada 24 h
      (`setInterval(...).unref()`), emitindo `orders_anonymized` com a
      contagem (RF-004) — `server/orders.js`
- [ ] T010 Resiliência: arranque aborta com `db_unavailable` se a BD não
      responder; erro de query em runtime responde `503 {error}` e o pool
      reconecta sozinho (casos extremos da spec) — `server/index.js`,
      `server/db.js`
- [ ] T011 Importação única do `server/data/orders.json` da spec 001:
      `INSERT ... ON CONFLICT (id) DO NOTHING` e renomear para
      `orders.json.imported` (RF-007) — `server/orders.js`

## Fase D — Integração e polimento

- [ ] T012 Instrumentação (Artigo II): confirmar que os eventos de negócio da
      spec 001 (`order_created`, `order_not_found`, `orders_anonymized`)
      continuam a ser emitidos e que os novos eventos de infraestrutura
      (`db_connected`, `db_unavailable`, `db_query`) aparecem nos logs —
      `server/index.js`, `server/orders.js`, `server/db.js`
- [ ] T013 [P] Documentação: secção "Base de dados" no README (subir com
      Docker, `DATABASE_URL`, esquema automático) — `README.md`
- [ ] T014 Validar todos os critérios de aceitação e casos extremos com
      [quickstart.md](quickstart.md); atualizar o estado da spec e a tabela
      em `specs/README.md` — `specs/README.md`, `specs/002-persistencia-postgres/spec.md`

## Ordem de execução

```
T001 [P], T002 [P] ──┐
T003 → T004 [P] → T005 ─┬→ T006, T007 [P] (testes primeiro, a falhar)
                        └→ T008 → T009 → T010 → T011
                                            T012 → T013 [P] → T014
```
