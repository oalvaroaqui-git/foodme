# Modelo de Dados — Persistência de Pedidos (Fase 1)

## Entidade: Pedido (Order)

| Campo           | Tipo               | Origem / Regra                                          |
|-----------------|--------------------|----------------------------------------------------------|
| `id`            | string (UUID v4)   | Gerado pelo servidor (`crypto.randomUUID()`) — RF-003    |
| `createdAt`     | string (ISO 8601)  | Gerado pelo servidor no momento da criação               |
| `restaurant`    | objeto             | `{ id, name }` — do corpo do pedido                      |
| `items`         | array (mín. 1)     | `[{ name, price, qty }]` — do corpo; vazio → 400         |
| `total`         | número             | Calculado no servidor: Σ `price × qty` (não confiar no cliente) |
| `paymentMethod` | string \| null     | Extraído de `payment`; **único** dado de pagamento persistido — RF-005 |
| `deliverTo`     | objeto \| null     | `{ name, address }`; removido (→ `null`) 30 dias após `createdAt` — RF-006 |

## Regras de transformação (entrada → persistido)

1. O corpo do `POST /api/order` traz `items`, `restaurant`, `payment`, `deliverTo`
   (formato atual do frontend — `cart.submitOrder()`).
2. O servidor **descarta** tudo de `payment` exceto o método; nunca persiste
   números de cartão, titulares ou códigos, mesmo que enviados.
3. `total` é recalculado no servidor a partir dos itens.
4. `deliverTo` guarda apenas `name` e `address`.

## Ciclo de vida

```
criado (deliverTo preenchido)
   │  30 dias após createdAt (rotina de anonimização)
   ▼
anonimizado (deliverTo = null; itens/restaurante/total mantidos)
```

Não há remoção de pedidos — apenas anonimização dos dados pessoais.
