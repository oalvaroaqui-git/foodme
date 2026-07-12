# Constituição do Projeto FoodMe

Princípios inegociáveis que governam todas as specs, planos e implementações
deste projeto. Qualquer plano que viole um destes artigos deve justificar a
exceção explicitamente na secção "Complexity Tracking" do plano.

## Artigo I — Simplicidade primeiro

A aplicação é uma base de demonstração para exercícios de observabilidade.
Cada funcionalidade deve usar o mínimo de dependências possível; a introdução
de uma nova dependência exige justificação na spec.

## Artigo II — Observabilidade obrigatória

Toda a funcionalidade nova deve nascer instrumentada: logging estruturado
de eventos de negócio relevantes e pontos de medição claros. Nenhum fluxo
de negócio pode ser "invisível" em produção.

## Artigo III — API consistente

Os endpoints seguem o padrão existente (`/api/<recurso>`), respondem JSON e
usam códigos HTTP semânticos. Alterações contratuais à API exigem definição
prévia em `contracts/` na spec correspondente.

## Artigo IV — Testável por contrato

Cada spec define critérios de aceitação verificáveis antes de qualquer
implementação. A implementação só está concluída quando os critérios de
aceitação da spec passam.

## Artigo V — Sem segredos no repositório

Credenciais e chaves vivem apenas em `.env` (não versionado em produção)
ou no gestor de segredos do ambiente de execução.

---

**Versão**: 1.0.0 | **Ratificada**: 2026-07-11 | **Última alteração**: 2026-07-11
