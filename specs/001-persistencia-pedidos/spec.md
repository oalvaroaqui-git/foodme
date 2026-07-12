# Especificação da Funcionalidade: Persistência de Pedidos

**Branch**: `001-persistencia-pedidos`
**Criada**: 2026-07-11
**Estado**: Aprovada

## Resumo

Hoje, os pedidos submetidos no checkout não são guardados — o servidor devolve
apenas um `orderId` gerado a partir do relógio. O negócio precisa de consultar
pedidos passados (para suporte ao cliente e análise), pelo que os pedidos devem
passar a ser persistidos e consultáveis.

## Cenários de Utilizador

### História principal
Como operador da plataforma, quero que cada pedido submetido fique registado
para poder consultá-lo mais tarde por identificador.

### Critérios de aceitação
1. **Dado** um carrinho válido, **quando** o cliente conclui o checkout,
   **então** o pedido é persistido com identificador único, itens, restaurante,
   dados de entrega e data/hora.
2. **Dado** um pedido persistido, **quando** consulto o seu identificador,
   **então** recebo os dados completos do pedido.
3. **Dado** um reinício do servidor, **quando** consulto um pedido feito antes
   do reinício, **então** o pedido continua acessível.

### Casos extremos
- Pedido sem itens: deve ser rejeitado com erro claro.
- Consulta de identificador inexistente: resposta 404 com mensagem.

## Requisitos

### Funcionais
- **RF-001**: O sistema DEVE persistir cada pedido submetido com sucesso.
- **RF-002**: O sistema DEVE permitir consultar um pedido por identificador.
- **RF-003**: O identificador do pedido DEVE ser único e não previsível.
- **RF-004**: Os pedidos DEVEM sobreviver a reinícios do servidor.
- **RF-005**: Dos dados de pagamento, o sistema DEVE persistir apenas o método
  (ex.: "cartão"); números, titulares e códigos NUNCA são persistidos.
- **RF-006**: Os dados de entrega (nome e morada) DEVEM ser removidos do pedido
  30 dias após a criação; o restante do pedido (itens, restaurante, total)
  é mantido para análise.

### Entidades envolvidas
- **Pedido**: identificador, restaurante, itens (nome, preço, quantidade),
  total, dados de entrega, data/hora de criação.

## Clarificações resolvidas (2026-07-11)

- **Dados de pagamento**: guardar apenas o método de pagamento (→ RF-005).
- **Retenção dos dados de entrega**: retenção com prazo de 30 dias, após o qual
  nome e morada são removidos do pedido (→ RF-006).

## Fora de âmbito

- Estados do pedido (confirmado, em entrega, entregue).
- Listagem/pesquisa de pedidos (apenas consulta por identificador).
- Interface de administração.
