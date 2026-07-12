# Quickstart — Validação Manual (Fase 1)

Valida os critérios de aceitação da [spec](spec.md) contra um servidor local.

## Preparação

```bash
npm start          # http://localhost:3000
```

## Critério 1 — Pedido persistido no checkout

```bash
ORDER_ID=$(curl -s -X POST http://localhost:3000/api/order \
  -H 'Content-Type: application/json' \
  -d '{
    "items": [{"name": "Currywurst mit Brötchen", "price": 5.95, "qty": 2}],
    "restaurant": {"id": "esthers", "name": "Esther'\''s German Saloon"},
    "payment": {"type": "card", "number": "4111111111111111"},
    "deliverTo": {"name": "Ana", "address": "Rua Principal 1"}
  }' | node -pe 'JSON.parse(require("fs").readFileSync(0)).orderId')
echo "$ORDER_ID"    # UUID, não timestamp
```

✅ Resposta `201` com `orderId` em formato UUID (RF-001, RF-003).

## Critério 2 — Consulta por identificador

```bash
curl -s http://localhost:3000/api/order/$ORDER_ID | node -pe '
  const o = JSON.parse(require("fs").readFileSync(0));
  [o.total === 11.9, o.paymentMethod, o.deliverTo.name, !JSON.stringify(o).includes("4111")]'
```

✅ `200` com o pedido completo; `total` calculado no servidor (11.9);
`paymentMethod` presente mas **nenhum número de cartão** persistido (RF-002, RF-005).

## Critério 3 — Sobrevive a reinícios

```bash
npm stop && npm start
curl -s http://localhost:3000/api/order/$ORDER_ID   # ainda 200 (RF-004)
```

## Casos extremos

```bash
# Pedido sem itens → 400
curl -si -X POST http://localhost:3000/api/order \
  -H 'Content-Type: application/json' -d '{"items": []}' | head -1

# Identificador inexistente → 404
curl -si http://localhost:3000/api/order/00000000-0000-0000-0000-000000000000 | head -1
```

## Anonimização (RF-006)

Editar `server/data/orders.json` recuando `createdAt` de um pedido 31 dias,
reiniciar o servidor e confirmar que `deliverTo` passou a `null` e que o log
regista `orders_anonymized`.
