# Tarefas: Persistência de Pedidos

**Plano**: [plan.md](plan.md)

Convenções: `[P]` = paralelizável (ficheiros independentes).
Cada tarefa indica o(s) ficheiro(s) exato(s) que toca.

## Fase A — Fundações

- [ ] T001 Criar modelo `Order`: normaliza o corpo do pedido — gera `id`
      (`crypto.randomUUID()`) e `createdAt` (ISO 8601), recalcula `total`
      (Σ `price × qty`), extrai `paymentMethod` de `payment` descartando o
      resto (RF-005), reduz `deliverTo` a `{name, address}` — `server/orders.js`
- [ ] T002 Criar `OrderStorage`: carrega `server/data/orders.json` no arranque
      (cria `[]` se não existir), `add()` com escrita imediata no ficheiro
      (write-through, RF-004), `getById()` — `server/orders.js`
- [ ] T003 [P] Ativar o logger `pino` (dependência já instalada; hoje
      comentado) — `server/index.js`

## Fase B — Testes de contrato (antes da implementação)

Usar o runner nativo `node:test` (sem dependências novas — Artigo I) contra
o contrato [contracts/order-api.yaml](contracts/order-api.yaml).

- [ ] T004 Teste de contrato `POST /api/order`: corpo válido → `201` com
      `orderId` UUID; `items` vazio/ausente → `400` com `error`; números de
      cartão enviados em `payment` não aparecem no pedido persistido —
      `test/order-api.test.js`
- [ ] T005 Teste de contrato `GET /api/order/:id`: id existente → `200` com
      pedido completo (`total` recalculado); id inexistente → `404` com
      `error` — `test/order-api.test.js`
- [ ] T006 [P] Adicionar script `test` (`node --test test/`) — `package.json`

## Fase C — Implementação

- [ ] T007 `POST /api/order`: valida itens (vazio → `400`), cria `Order`,
      persiste via `OrderStorage`, responde `201 {orderId}` — `server/index.js`
- [ ] T008 `GET /api/order/:id`: devolve `200` com o pedido ou `404` —
      `server/index.js`

## Fase D — Integração e polimento

- [ ] T009 Rotina de anonimização (RF-006): no arranque e a cada 24 h
      (`setInterval(...).unref()`), remove `deliverTo` de pedidos com
      `createdAt` > 30 dias e regrava o ficheiro se houver alterações —
      `server/orders.js`
- [ ] T010 Instrumentação (Artigo II): emitir `order_created` (orderId,
      restaurante, nº itens, total), `order_not_found` (orderId) e
      `orders_anonymized` (contagem) via pino — `server/index.js`, `server/orders.js`
- [ ] T011 Garantir que `orders.json` não versiona dados reais: entrada no
      `.gitignore` — `.gitignore`
- [ ] T012 Validar todos os critérios de aceitação com
      [quickstart.md](quickstart.md) e atualizar a tabela da API no README
      (novo `GET /api/order/:id`, `POST` agora persiste) — `README.md`

## Ordem de execução

```
T001 → T002 ─┬→ T004, T005 (testes primeiro, a falhar) → T007 → T008
T003 [P] ────┘                                                    │
                                              T009 → T010 → T011 → T012
```
