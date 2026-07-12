# Especificação da Funcionalidade: Persistência em PostgreSQL

**Branch**: `002-persistencia-postgres`
**Criada**: 2026-07-11
**Estado**: Aprovada

## Resumo

A spec 001 introduz a persistência de pedidos em ficheiro JSON, suficiente para
sobreviver a reinícios mas limitada: sem consultas concorrentes seguras, sem
integridade transacional e sem espaço para crescer (listagens, análises).
O negócio decidiu adotar uma base de dados relacional — **PostgreSQL**, por
decisão explícita do stakeholder — como armazenamento dos pedidos, que também
servirá de alvo para os exercícios de observabilidade do projeto
(instrumentação de queries, pool de ligações, latência de base de dados).

## Cenários de Utilizador

### História principal
Como operador da plataforma, quero que os pedidos sejam guardados numa base de
dados PostgreSQL para ter garantias de integridade e consultas fiáveis mesmo
com acessos concorrentes.

### Critérios de aceitação
1. **Dado** um carrinho válido, **quando** o cliente conclui o checkout,
   **então** o pedido fica gravado na base de dados PostgreSQL com todos os
   campos definidos na spec 001.
2. **Dado** um pedido gravado, **quando** consulto `GET /api/order/:id`,
   **então** recebo os mesmos dados que o contrato da spec 001 define — o
   contrato da API não muda.
3. **Dado** um reinício do servidor (ou do contentor da aplicação),
   **quando** consulto um pedido anterior, **então** ele continua acessível.
4. **Dado** um ambiente novo, **quando** arranco a base de dados e a aplicação
   pela primeira vez, **então** o esquema é criado automaticamente, sem passos
   manuais de SQL.

### Casos extremos
- Base de dados indisponível no arranque: a aplicação falha de forma clara e
  audível (log estruturado com o motivo), em vez de arrancar "coxa".
- Base de dados cai com a aplicação no ar: pedidos falham com `503` e mensagem
  clara; a aplicação recupera sozinha quando a base de dados voltar.
- Pedidos existentes em `server/data/orders.json` (da spec 001): são importados
  uma única vez, sem duplicação em arranques seguintes.

## Requisitos

### Funcionais
- **RF-001**: O sistema DEVE persistir os pedidos em PostgreSQL, mantendo o
  modelo de dados e as regras de transformação da spec 001 (total recalculado,
  apenas o método de pagamento, `deliverTo` anonimizável).
- **RF-002**: O contrato público da API (`POST /api/order`,
  `GET /api/order/:id`) NÃO PODE mudar — a troca de armazenamento é invisível
  para o cliente.
- **RF-003**: O esquema da base de dados DEVE ser criado/atualizado de forma
  idempotente no arranque da aplicação.
- **RF-004**: A anonimização de dados de entrega após 30 dias (RF-006 da
  spec 001) DEVE continuar a funcionar sobre a base de dados.
- **RF-005**: As credenciais da base de dados DEVEM vir exclusivamente do
  ambiente (`.env` / gestor de segredos) — nunca do repositório.
- **RF-006**: O ambiente de desenvolvimento local DEVE poder subir a base de
  dados com um único comando, sem instalação manual de PostgreSQL.
- **RF-007**: Pedidos pré-existentes no ficheiro JSON da spec 001 DEVEM ser
  importados para a base de dados uma única vez.

### Entidades envolvidas
- **Pedido**: a mesma entidade da spec 001 (ver
  [../001-persistencia-pedidos/data-model.md](../001-persistencia-pedidos/data-model.md)),
  agora materializada como tabela relacional.

## Clarificações pendentes

Nenhuma — a escolha do motor (PostgreSQL) foi decisão explícita do stakeholder
(2026-07-11).

## Fora de âmbito

- Migrar o catálogo de restaurantes (`server/data/restaurants.json`) para a
  base de dados — continua em ficheiro.
- Listagem/pesquisa de pedidos (mantém-se apenas a consulta por id).
- Réplicas, backups e alta disponibilidade da base de dados.
- ORM ou camada de migrações versionadas (excesso para a dimensão do projeto).
