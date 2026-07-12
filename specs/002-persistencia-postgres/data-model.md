# Modelo de Dados — Persistência em PostgreSQL (Fase 1)

A entidade Pedido é a da spec 001
([data-model.md](../001-persistencia-pedidos/data-model.md)); este documento
define apenas a sua materialização relacional.

## Tabela `orders`

| Coluna            | Tipo            | Regra                                                    |
|-------------------|-----------------|----------------------------------------------------------|
| `id`              | `uuid` PK       | Gerado pela aplicação (`crypto.randomUUID()`) — RF-003 da spec 001 |
| `created_at`      | `timestamptz`   | `DEFAULT now()`; base da anonimização                    |
| `restaurant_id`   | `text NOT NULL` | Do corpo do pedido                                       |
| `restaurant_name` | `text NOT NULL` | Do corpo do pedido                                       |
| `items`           | `jsonb NOT NULL`| `[{ name, price, qty }]`; a validação "mín. 1" é da aplicação |
| `total`           | `numeric(10,2) NOT NULL` | Recalculado no servidor (Σ `price × qty`)       |
| `payment_method`  | `text`          | Único dado de pagamento persistido (RF-005 da spec 001)  |
| `deliver_to`      | `jsonb`         | `{ name, address }`; `NULL` após anonimização            |

## Índices

- PK em `id` cobre `GET /api/order/:id`.
- Índice parcial `idx_orders_anonymize` em `created_at`
  (`WHERE deliver_to IS NOT NULL`) para a rotina de anonimização não fazer
  seq scan à medida que a tabela cresce.

## Anonimização (RF-004)

```sql
UPDATE orders
   SET deliver_to = NULL
 WHERE created_at < now() - interval '30 days'
   AND deliver_to IS NOT NULL;
```

Executada no arranque e a cada 24 h; o número de linhas afetadas alimenta o
evento `orders_anonymized`.

## Mapeamento API ↔ tabela

O contrato JSON da API (spec 001) usa `camelCase`; as colunas usam
`snake_case`. A conversão é feita na camada `OrderStorage` — o formato de
resposta do `GET /api/order/:id` não muda (RF-002).
