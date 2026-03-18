# Service: agent-architect-ui

## Purpose

A web-based orchestration UI that serves as the visual control plane for Agent Architect projects. It solves the visibility gap — Agent Architect is powerful but invisible as a folder-of-markdown framework operated via CLI slash commands. The UI provides a dashboard for phase progression, visual manifest editing, spec/contract review, and the Human Review Gate between Phase 4→5.

## Responsibilities

- Visualize phase pipeline progression and service health status
- Render and browse specs and contracts (markdown + OpenAPI)
- Provide a visual editor for `manifest.yaml` (add/edit services, dependencies, tech stack)
- Implement the Human Review Gate approval workflow with sign-off tracking
- Trigger agent phase execution via headless CLI and display real-time progress
- Display quality scorecard results from Phase 7 reviews

### Screens

Each responsibility maps to a screen in the UI:

| Screen | Purpose | UI Patterns |
|---|---|---|
| Project Dashboard | Phase pipeline view, service status cards, health metrics | Cards, data table, charts |
| Manifest Editor | Visual manifest.yaml editing (services, deps, tech stack) | Form, input validation, YAML preview |
| Service Map | Dependency graph visualization (services + events) | D3 or Mermaid graph, interactive nodes |
| Spec Viewer/Editor | Markdown rendering + inline commenting for specs | Markdown renderer, two-column layout |
| Contract Browser | OpenAPI spec viewer, event schema browser | Data table, code highlighting |
| Review Gate | Approval workflow with sign-off tracking | Modal, form, audit trail table |
| Build Monitor | Real-time build progress across services | SSE stream, status indicators, terminal output |
| Quality Scorecard | Phase 7 review results, coverage, security findings | Charts, data table, score badges |

## Key Entities

| Entity | Description | Key Fields |
|--------|-------------|------------|
| Manifest | Project configuration and service registry | services, tech_stack, quality_gates, approvals |
| Phase | A step in the agent pipeline (0-7) | number, name, status, completion_date |
| Service | A service defined in the manifest | name, type, status, dependencies, specs |
| Spec | Generated specification for a service | service_name, content (markdown), version |
| Contract | Cross-service API contract | provider, consumer, endpoints, events |
| Approval | Review gate sign-off record | phase, approved_by, date, notes |

## API Consumers

| Consumer | Endpoints Used | Notes |
|----------|---------------|-------|
| Browser (SPA) | All BFF API routes | Primary consumer — all interaction through agent-orchestration-bff |

## Events

### Publishes

None — the UI triggers actions via HTTP requests to the BFF. Domain events (`approval.granted`, `phase.triggered`) are published by `agent-orchestration-bff`.

### Subscribes To

| Event | Source Service | Action Taken |
|-------|---------------|-------------|
| sse:file-change | agent-orchestration-bff | Refresh dashboard, spec viewer, phase status |
| sse:phase-output | agent-orchestration-bff | Display real-time build output in Build Monitor |
| sse:phase-complete | agent-orchestration-bff | Update phase status, show completion notification |

## External Dependencies

- **agent-orchestration-bff** — all data access and agent execution goes through the BFF
- **UI template / component library** — base scaffolding for layout, forms, tables, and theming (e.g., a Next.js starter, MUI, shadcn/ui, or an internal template)

## Special Considerations

- The UI is a **separate repository** from the planning repo — see `standards/ui-architecture.md` for architectural patterns and rationale
- No direct filesystem access — all data comes from the BFF
- Must handle long-running agent executions gracefully (SSE streaming, timeout handling)
- Review Gate is the critical workflow — this is the Human Review Gate between Phase 4→5 where humans approve specs/contracts before code generation begins
- Must work in solo mode (no auth) and team mode (pluggable SSO/OAuth) — auth should not be hardcoded to a specific provider
