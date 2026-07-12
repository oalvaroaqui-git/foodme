# Investigação — Persistência de Pedidos (Fase 0)

## 1. Estratégia de persistência

**Decisão**: ficheiro JSON dedicado (`server/data/orders.json`) com escrita
imediata a cada pedido.

**Alternativas consideradas**:
- *Reutilizar o padrão dos restaurantes (gravar só no SIGINT)* — rejeitada:
  uma queda do processo perderia pedidos já confirmados ao cliente (viola RF-004).
- *SQLite/lowdb/nedb* — rejeitadas: introduzem dependência nova sem necessidade
  para o volume de uma app de demonstração (viola Artigo I).

**Nota de escala**: a escrita reescreve o ficheiro completo; aceitável para
demonstração. Se o volume crescer, o storage é substituível por trás da mesma
interface (`OrderStorage`).

## 2. Geração de identificadores

**Decisão**: `crypto.randomUUID()` (built-in do Node desde a v14.17).

**Alternativas consideradas**:
- *`Date.now()` (atual)* — rejeitada: previsível e colide com pedidos no mesmo
  milissegundo (viola RF-003).
- *nanoid/uuid (npm)* — rejeitadas: dependência nova desnecessária (Artigo I).

## 3. Agendamento da anonimização (RF-006)

**Decisão**: verificação no arranque + `setInterval` de 24 h com `.unref()`
(não impede o processo de terminar). Remove o campo `deliverTo` de pedidos
com `createdAt` > 30 dias e regrava o ficheiro se houver alterações.

**Alternativas consideradas**:
- *cron do sistema* — rejeitada: dependência de infraestrutura externa à app.
- *verificação apenas na leitura (lazy)* — rejeitada: dados expirados
  permaneceriam no ficheiro em disco, que é o que a RF-006 quer evitar.
