# FoodMe

Aplicação de demonstração para pedidos de comida a restaurantes locais, construída com **AngularJS 1.x** no frontend e **Node.js/Express** no backend. Este projeto tem origem no workshop [angular-seed](http://github.com/angular/angular-seed) e foi posteriormente adaptado (ver histórico de commits) como aplicação de referência para ensinar **instrumentação de observabilidade / APM** com o New Relic — daí existirem, no código, vários pontos de instrumentação comentados prontos a ativar.

---

## Arquitetura

A aplicação segue um modelo clássico de **SPA (Single Page Application) + API REST**, sem base de dados externa:

```
┌─────────────────────────┐        HTTP / JSON        ┌───────────────────────────┐
│  Frontend (AngularJS)   │  ────────────────────────► │  Backend (Express)        │
│  app/                   │  ◄──────────────────────── │  server/                  │
│  - Controllers          │                             │  - Rotas REST /api/*      │
│  - Services (cart, etc) │                             │  - Model (Restaurant)     │
│  - Views (templates)    │                             │  - Storage em memória     │
└─────────────────────────┘                             └───────────┬───────────────┘
                                                                      │
                                                            lê/grava ao arrancar/parar
                                                                      ▼
                                                          server/data/restaurants.json
```

### Frontend (`app/`)
- **AngularJS 1.x** (`ngResource`), roteamento client-side via `$routeProvider` (`app/js/app.js`).
- **Controllers** (`app/js/controllers/`): `RestaurantsController` (listagem, filtros por cozinha/preço/rating e ordenação), `MenuController` (menu de um restaurante), `CheckoutController` (submissão do pedido), `CustomerController` (dados do cliente), `ThankYouController`, `NavbarController`.
- **Services** (`app/js/services/`): `cart` (carrinho persistido em `localStorage`, cálculo de total, submissão do pedido via `$http`), `customer`, `Restaurant` (`$resource` sobre `/api/restaurant`), `alert`, `localStorage`.
- **Directives/Filters**: componentes de UI reutilizáveis (rating, checkbox list, formatação de valores em dólares, etc.).
- **Views** (`app/views/*.html`): templates renderizados dentro de `<ng-view>`.

### Backend (`server/`)
- **`start.js`** — ponto de entrada; define porta, diretório estático e ficheiro de dados, e arranca o servidor definido em `index.js`.
- **`index.js`** — configura o Express: logging de pedidos HTTP com `morgan`, motor de views `swig` (renderiza `server/templates/index.html`), servir ficheiros estáticos de `app/`, e a API REST.
- **`model.js`** — define `Restaurant` e `MenuItem` (validação, normalização de campos, criação a partir de linhas CSV).
- **`storage.js`** — `MemoryStorage`, um armazenamento **em memória** (array), sem persistência real durante a execução.
- **`server/data/`** — dados de seed (`restaurants.json`, e os CSVs originais `restaurants.csv`/`menus.csv` usados para os gerar).

### Persistência de dados
Não existe base de dados. Ao arrancar, o servidor lê `server/data/restaurants.json` e carrega os restaurantes para memória; ao receber `SIGINT` (Ctrl+C), grava o estado atual de volta no mesmo ficheiro. **Os pedidos (`/api/order`) não são persistidos** — o endpoint apenas responde com um `orderId` fictício (`Date.now()`).

### Observabilidade / APM
Este é o ponto central do propósito do repositório: existem vários trechos de instrumentação **comentados**, prontos para serem ativados como exercício:
- `server/index.js` — `require('newrelic')` (agente de servidor) e exposição de `app.locals.newrelic`.
- `server/templates/index.html` — placeholder `{{ newrelic.getBrowserTimingHeader() }}` para o **Browser Agent**.
- `server/index.js` (rota `POST /api/order`) — exemplo de **custom attributes** (cliente, restaurante, nº de itens, total do pedido).
- `app/js/services/cart.js` — exemplo de **custom page action** (`newrelic.addPageAction`) por item comprado.
- Logging estruturado com `pino` (dependência incluída, também comentado) e logging de acesso HTTP com `morgan` (ativo).
- Variáveis de ambiente `NEW_RELIC_APP_NAME` e `NEW_RELIC_LICENSE_KEY` já preparadas em `.env`.

---

## Lógica de negócio

Fluxo típico de utilização da aplicação:

1. **Identificação do cliente** (`/customer`) — nome e morada; sem morada definida, o utilizador é redirecionado para este passo antes de poder ver restaurantes.
2. **Listagem de restaurantes** (`/`) — consulta `GET /api/restaurant`, com filtro por tipo de cozinha, preço e classificação, e ordenação por coluna.
3. **Menu do restaurante** (`/menu/:restaurantId`) — consulta `GET /api/restaurant/:id` (inclui `menuItems`); os itens escolhidos são adicionados ao carrinho.
4. **Carrinho** — persistido em `localStorage`; impede misturar itens de restaurantes diferentes; calcula o total do pedido.
5. **Checkout** (`/checkout`) — submete o pedido via `POST /api/order` com itens, restaurante, dados de pagamento e dados de entrega.
6. **Confirmação** (`/thank-you`) — apresenta o `orderId` devolvido pela API.

### API REST (`server/index.js`)

| Método | Rota                  | Descrição                                                   |
|--------|------------------------|--------------------------------------------------------------|
| GET    | `/api/restaurant`      | Lista todos os restaurantes (sem `menuItems`)                |
| POST   | `/api/restaurant`      | Cria um restaurante                                          |
| GET    | `/api/restaurant/:id`  | Obtém um restaurante (com `menuItems`)                       |
| PUT    | `/api/restaurant/:id`  | Atualiza um restaurante (ou cria, se não existir)            |
| DELETE | `/api/restaurant/:id`  | Remove um restaurante                                        |
| POST   | `/api/order`           | Submete um pedido (não persiste; devolve `{ orderId }`)      |

---

## Requisitos

- Node.js `^22.16.0` (definido em `package.json` → `engines`). **Nota:** o `Dockerfile` atual usa `node:18-alpine`, uma versão inferior à exigida — a rever antes de usar em produção.
- npm (instalado com o Node.js).

## Como correr a aplicação

### Localmente

```bash
cd foodme
npm install
npm start          # equivalente a: node --env-file=.env server/start.js
```

A aplicação abre automaticamente em `http://localhost:3000/` (porta configurável via variável de ambiente `PORT`).

Para parar o servidor de forma limpa (grava o estado dos restaurantes em `restaurants.json`):

```bash
# Ctrl+C no terminal, ou:
npm stop            # envia SIGINT ao processo node
```

### Com Docker

```bash
cd foodme
docker build -t foodme .
docker run -p 3000:3000 --env-file .env foodme
```

### Variáveis de ambiente (`.env`)

| Variável                  | Finalidade                                   |
|----------------------------|-----------------------------------------------|
| `PORT`                     | Porta do servidor Express (default: `3000`)   |
| `NEW_RELIC_APP_NAME`       | Nome da aplicação no New Relic                |
| `NEW_RELIC_LICENSE_KEY`    | Chave de licença do agente New Relic          |

## Comandos úteis para analisar a aplicação

```bash
# Ver dependências e scripts disponíveis
cat package.json

# Verificar estrutura de rotas e lógica do servidor
cat server/index.js

# Inspecionar dados de seed dos restaurantes
cat server/data/restaurants.json | jq .        # ou restaurants.csv / menus.csv

# Seguir os logs de acesso HTTP (morgan, formato "combined") em tempo real
npm start

# Procurar todos os pontos de instrumentação de observabilidade (comentados)
grep -rn "newrelic\|pino" server app

# Ver histórico de evolução da app (ex.: como a instrumentação foi introduzida)
git log --oneline
```

## Estrutura de diretórios

```
foodme/
├── app/                    # Frontend AngularJS
│   ├── css/                # Bootstrap + estilos próprios
│   ├── img/                # Imagens (restaurantes, ícones)
│   ├── js/
│   │   ├── controllers/    # Controllers Angular
│   │   ├── directives/     # Diretivas customizadas
│   │   ├── filters/        # Filtros (dollars, stars)
│   │   └── services/       # Serviços (cart, customer, Restaurant, ...)
│   ├── lib/angular/         # Biblioteca AngularJS
│   └── views/               # Templates HTML das rotas
├── server/
│   ├── data/                # Dados de seed (JSON/CSV)
│   ├── templates/           # Template swig da página principal
│   ├── index.js             # Configuração do Express e rotas da API
│   ├── model.js              # Modelos Restaurant / MenuItem
│   ├── storage.js            # Armazenamento em memória
│   └── start.js               # Ponto de entrada
├── Dockerfile
├── package.json
└── .env                        # Configuração local (não versionar em produção)
```

## Licença

MIT
