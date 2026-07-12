# Quickstart — Validação Manual (Persistência em PostgreSQL)

Valida os critérios de aceitação da [spec.md](spec.md).

## Preparação

```bash
docker compose up -d          # sobe o PostgreSQL local (aguarda healthcheck)
cp -n .env.example .env       # DATABASE_URL de desenvolvimento
npm start                     # deve logar db_connected e aplicar o esquema
```

## Critério 1 + 2 — pedido persistido e consultável

```bash
ORDER_ID=$(curl -s -X POST http://localhost:3000/api/order \
  -H 'Content-Type: application/json' \
  -d '{"restaurant":{"id":"esthers","name":"Esther'\''s German Saloon"},
       "items":[{"name":"Wienerschnitzel","price":8.95,"qty":2}],
       "payment":{"type":"visa","number":"4111111111111111"},
       "deliverTo":{"name":"João Silva","address":"Rua das Flores, 432"}}' \
  | node -pe 'JSON.parse(require("fs").readFileSync(0)).orderId')

curl -s http://localhost:3000/api/order/$ORDER_ID
# → 200 com o pedido; total = 17.90; payment_method presente, número de cartão AUSENTE
```

Confirmar na base de dados que o cartão não foi persistido:

```bash
docker compose exec db psql -U foodme -c \
  "SELECT id, total, payment_method, deliver_to FROM orders WHERE id = '$ORDER_ID';"
```

## Critério 3 — sobrevive a reinícios

```bash
npm stop && npm start
curl -s http://localhost:3000/api/order/$ORDER_ID   # → 200, mesmo pedido
```

## Critério 4 — esquema automático em ambiente novo

```bash
docker compose down -v && docker compose up -d && npm start
# → arranque limpo: esquema criado sem passos manuais (log db_connected)
```

## Casos extremos

```bash
docker compose stop db && npm start        # → processo termina com db_unavailable
docker compose start db && npm start       # com a app no ar: parar a BD →
curl -i -X POST http://localhost:3000/api/order -d '...'   # → 503 {error}
docker compose start db                    # → volta a 201 sem reiniciar a app
```

## Importação única (RF-007)

Com um `server/data/orders.json` não vazio da spec 001: primeiro arranque
importa e renomeia para `orders.json.imported`; segundo arranque não duplica
(`SELECT count(*) FROM orders;` estável).
