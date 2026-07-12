# Specs — Spec-Driven Development

Cada funcionalidade vive numa pasta numerada `NNN-nome-da-funcionalidade/`,
que acompanha o branch com o mesmo nome. O fluxo é sempre:

```
specify → clarify → plan → tasks → implement
```

1. **specify** — criar `spec.md` a partir de `.specify/templates/spec-template.md`.
   Descreve o QUÊ e o PORQUÊ; zero decisões técnicas.
2. **clarify** — resolver todos os `[PRECISA CLARIFICAÇÃO]` da spec antes de planear.
3. **plan** — criar `plan.md` a partir do template; validar contra a
   constituição (`.specify/memory/constitution.md`). Gera os artefactos de
   desenho: `research.md`, `data-model.md`, `contracts/`, `quickstart.md`.
4. **tasks** — decompor o plano em `tasks.md`, com tarefas pequenas, ordenadas
   e marcadas como paralelizáveis quando independentes.
5. **implement** — executar as tarefas; a funcionalidade só está concluída
   quando os critérios de aceitação da spec passam.

## Estrutura de uma spec

```
specs/NNN-nome-da-funcionalidade/
├── spec.md          # O QUÊ/PORQUÊ — requisitos e critérios de aceitação
├── plan.md          # COMO — contexto técnico, fases, verificação da constituição
├── research.md      # Fase 0 — incógnitas técnicas resolvidas
├── data-model.md    # Fase 1 — entidades e relações
├── contracts/       # Fase 1 — contratos da API (OpenAPI/JSON Schema)
├── quickstart.md    # Fase 1 — guia de validação manual dos cenários
└── tasks.md         # Fase 2 — decomposição em tarefas executáveis
```

## Specs existentes

| Nº  | Funcionalidade                              | Estado    |
|-----|---------------------------------------------|-----------|
| 001 | [Persistência de Pedidos](001-persistencia-pedidos/spec.md) | Pronta para implementar |
| 002 | [Persistência em PostgreSQL](002-persistencia-postgres/spec.md) | Pronta para implementar (depende da 001) |
