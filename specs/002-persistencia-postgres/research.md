# Investigação — Persistência em PostgreSQL (Fase 0)

## 1. Driver `pg` vs ORM (Sequelize/Prisma/knex)

**Decisão**: `pg` puro.

- O domínio tem **uma** entidade e três operações (inserir, obter por id,
  anonimizar). Um ORM traria modelos, migrações e geração de código para
  eliminar meia dúzia de linhas de SQL.
- O Artigo I exige o mínimo de dependências; `pg` é o driver oficial, estável
  há mais de uma década e sem dependências transitivas relevantes.
- SQL explícito é pedagogicamente melhor para os exercícios de observabilidade
  (queries visíveis nos logs e no `pg_stat_statements`).

## 2. Gestão de esquema

**Decisão**: `schema.sql` idempotente aplicado no arranque.

- `CREATE TABLE IF NOT EXISTS` cobre o requisito RF-003 (arranque limpo em
  ambiente novo) sem ferramenta de migrações.
- Ferramentas de migração (node-pg-migrate, dbmate) só se justificam à segunda
  alteração de esquema — registado como fora de âmbito na spec.

## 3. PostgreSQL local

**Decisão**: Docker Compose com `postgres:16-alpine`.

- Um comando (`docker compose up -d`) cumpre o RF-006; healthcheck
  (`pg_isready`) permite aguardar a prontidão de forma fiável.
- Volume nomeado preserva dados entre reinícios do contentor, alinhado com o
  critério de aceitação 3 da spec.
- Alternativas descartadas: instalação nativa (fricção de setup, versões
  divergentes) e SQLite (não é o motor decidido pelo stakeholder e não exercita
  observabilidade de um serviço externo).

## 4. Pool de ligações

**Decisão**: `pg.Pool` com os defaults (10 ligações).

- O tráfego de demonstração não exige afinação; o pool expõe métricas
  (`totalCount`, `idleCount`, `waitingCount`) úteis para instrumentação futura.
- O pool reconecta sozinho após queda da base de dados, o que satisfaz o caso
  extremo "a BD volta e a aplicação recupera sem reinício".
