# Plano de Implementação: Persistência de Pedidos

**Spec**: [spec.md](spec.md)
**Criado**: 2026-07-11

## Contexto técnico

- **Linguagem/runtime**: Node.js >=22.16.0, Express 4.x (existente)
- **Dependências novas**: nenhuma — usa `node:crypto` (`randomUUID`) para
  identificadores e `node:fs` para persistência; ativa o `pino`, que já é
  dependência do projeto (Artigo I)
- **Armazenamento**: ficheiro JSON (`server/data/orders.json`), com escrita
  imediata a cada pedido (write-through) — ao contrário dos restaurantes, os
  pedidos não podem depender do `SIGINT` para persistir (RF-004)
- **Observabilidade** (Artigo II): eventos de negócio estruturados via `pino`:
  - `order_created` — orderId, restaurante, nº de itens, total
  - `order_not_found` — orderId consultado sem correspondência
  - `orders_anonymized` — nº de pedidos cujos dados de entrega expiraram (RF-006)

## Verificação da Constituição

| Artigo | Cumpre? | Justificação (se não) |
|--------|---------|------------------------|
| I — Simplicidade | ✅ | Zero dependências novas; reutiliza o padrão ficheiro JSON já existente |
| II — Observabilidade | ✅ | Eventos `order_created` / `order_not_found` / `orders_anonymized` via pino |
| III — API consistente | ✅ | `POST /api/order` mantém contrato; novo `GET /api/order/:id` segue o padrão |
| IV — Testável por contrato | ✅ | Contratos em `contracts/`; validação manual em `quickstart.md` |
| V — Sem segredos | ✅ | Nenhum segredo envolvido; dados de pagamento reduzidos ao método (RF-005) |

## Estrutura / ficheiros afetados

```
server/
├── orders.js            # NOVO — modelo Order + OrderStorage (JSON write-through
│                        #        + anonimização após 30 dias)
├── index.js             # ALTERADO — POST /api/order persiste; novo GET /api/order/:id;
│                        #            logger pino ativado para eventos de negócio
└── data/
    └── orders.json      # NOVO — criado vazio ([]) no primeiro arranque
```

## Decisões de desenho

1. **Identificador**: `crypto.randomUUID()` — único e não previsível (RF-003),
   sem dependências. O `Date.now()` atual falha RF-003 (previsível e colide
   sob concorrência).
2. **Write-through**: cada pedido é gravado no ficheiro no momento da criação;
   uma queda do processo não perde pedidos já confirmados ao cliente (RF-004).
3. **Anonimização (RF-006)**: campo `createdAt` (ISO 8601) em cada pedido; uma
   rotina remove `deliverTo` dos pedidos com mais de 30 dias. Corre no arranque
   e a cada 24 h (`setInterval` com `unref()` para não segurar o processo).
4. **Validação**: pedido sem itens → `400` com mensagem (caso extremo da spec);
   consulta de id inexistente → `404` (caso extremo da spec).
5. **Pagamento (RF-005)**: do objeto `payment` recebido, persiste-se apenas
   `paymentMethod` (string); os restantes campos são descartados no servidor,
   garantindo a regra mesmo que o cliente envie mais dados.

## Fases

### Fase 0 — Investigação (research.md)
Resolvida — ver [research.md](research.md): estratégia de persistência,
geração de ids e agendamento da anonimização.

### Fase 1 — Desenho
- [data-model.md](data-model.md) — entidade Pedido e regras de transformação
- [contracts/order-api.yaml](contracts/order-api.yaml) — contrato OpenAPI dos
  dois endpoints
- [quickstart.md](quickstart.md) — validação manual dos critérios de aceitação

### Fase 2 — Decomposição em tarefas (tasks.md)
A gerar no passo `tasks` do fluxo. Ordenação prevista: storage → validação →
endpoints → anonimização → instrumentação; testes de contrato antes da
implementação de cada endpoint.

## Complexity Tracking

Nenhuma exceção à constituição.
