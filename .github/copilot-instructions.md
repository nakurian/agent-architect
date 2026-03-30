# Agent Architect

This is a **project planning repository**, not a code repository. It contains business context, specifications, and agent skills that drive the development of a multi-service system.

## Default Tech Stack

> The default tech stack for **new services** built through this framework is:
>
> - **Backend**: Java 21 · Spring Boot 3.4+ · Spring WebFlux (Netty)
> - **Frontend**: TypeScript · Next.js · React 18+ · MUI 6
> - **Database**: Couchbase · Hazelcast (cache) · Kafka (messaging)
> - **Shared Library**: Configurable via `manifest.yaml → tech_stack.shared_library`
> - **Build**: Gradle with Kotlin DSL (`build.gradle.kts`)
> - **Quality**: Spotless + Checkstyle (Google style, 0 violations) + JaCoCo (80% min)
>
> See `standards/backend-system-design-standard.md` for the complete backend standard.
> Override any of these in `manifest.yaml → tech_stack` during Phase 0 setup.

## How This Repo Works

### Sequential Mode (default)
1. **Setup Agent** interviews the human and populates manifest, standards, and project context (Phase 0)
2. **Spec Agents** read everything and generate detailed specs + test plans in `services/<name>/specs/`
3. **Contract Agents** ensure cross-service APIs are consistent in `contracts/`
4. **Builder Agents** take specs to separate code repos and build the services
5. **Validation Agents** verify cross-service integration

### Team Mode (optional — requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
Run `/project:team-start` after Phase 0 to spawn a 5-agent team that orchestrates Phases 1-7 automatically:
- **Team Lead / Product Owner** (opus) — orchestrates phases, enforces quality gates, human liaison
- **Sr. Solutions Architect** (opus) — discovery, architecture, contracts, cross-service review
- **Sr. Lead Engineer** (opus) — specs, test plans, builds services
- **Sr. QA & Security Engineer** (sonnet) — test augmentation, validation, security review
- **Sr. DevOps Engineer** (sonnet) — infrastructure, CI/CD, docker-compose, deployment review

Agents challenge each other's work and coordinate via task dependencies. The human approves at quality gates.

## Production Readiness Standards (All Agents)

Every agent MUST enforce these non-negotiable standards. These apply to ALL phases — specs, builds, reviews.

### Logging, Error Handling, Performance
Follow `standards/coding-standards.md` — the Logging Standards (including PII boundary rules) and Error Handling sections are **BINDING** for all phases. Do not duplicate those rules here; read them from the source.

### Architecture Decisions — GAN Method
For every significant technical decision, agents MUST:
1. **Generate** 2-3 viable options
2. **Analyze** trade-offs (complexity, performance, alignment with existing stack, K8s/deployment implications)
3. **Narrow** to recommended option with clear rationale
4. Always check existing services for patterns before introducing new libraries or approaches

### Branch Hygiene
- ALWAYS fetch latest before starting work: `git fetch origin`
- Create feature branch from latest: `git checkout -b feat/{ticket}-{feature} origin/{base-branch}`
- Single squashed commit per PR
- Code review BEFORE PR creation, not after

### Config Repo Awareness
When introducing new infrastructure (cache, message broker, external service):
- Check sibling service config repos for deployment patterns (RBAC, trust certs, discovery config)
- Ensure K8s manifests include required RBAC, volume mounts, and lifecycle hooks
- Document new environment variables in README

### Smart Codebase Navigation — Serena MCP
When `plugin:serena:serena` MCP is available, agents MUST prefer it over reading entire files:
- Use `get_symbols_overview` to understand file structure before reading code
- Use `find_symbol` to locate specific classes, methods, or fields by name
- Use `find_referencing_symbols` to trace where a symbol is used across the codebase
- Only use `read_file` or `find_symbol` with body when you need the actual implementation
- This dramatically reduces context usage — read 20 lines of a method body instead of 500 lines of a full file

When Serena is NOT available, be creative with context:
- Use `Grep` to find specific patterns instead of reading whole files
- Use `Glob` to find files by name pattern
- Read files with `offset` and `limit` to get only the section you need
- Never read an entire large file when you only need one method or config block

## Context Budget by Phase

Agents MUST read ONLY the files listed for their current phase. Do NOT read the entire `standards/` directory.

| Phase | Read These Files | Backend Standard Sections (if needed) |
|-------|-----------------|--------------------------------------|
| 0-setup | `manifest.yaml`, `context/PROJECT.md` | None |
| 1-discover | `manifest.yaml`, `context/**`, `services/*/CONTEXT.md` | None |
| 2-architect | `manifest.yaml`, `phases/1-discover.md`, `standards/coding-standards.md`, `standards/api-design.md` | §1, §5, §15 (principles, layers, cloud-native) |
| 3-specify | `manifest.yaml`, `phases/1-2`, `standards/coding-standards.md`, `standards/api-design.md`, `standards/testing-standards.md`, `services/<name>/CONTEXT.md` | §6–10, §12, §16 (controller→DTO, reactive, errors) |
| 4-contract | `manifest.yaml`, `phases/2-architect.md`, all `SPEC.md` files, `standards/api-design.md` | §24 only (API Design) |
| 5-build | (already explicit in 5-build.md) | Sections referenced by SPEC.md — use offset/limit |
| 6-validate | `manifest.yaml`, `contracts/*`, all `BUILD-REPORT.md` + `TEST-REPORT.md` | None |
| 7-review | Built code, `TEST-REPORT.md` files | §16, §20–23 (errors, observability, security, testing, quality) |

### Reading `backend-system-design-standard.md` Efficiently

This file is 2,454 lines. NEVER read the whole thing. Use offset/limit with this index:

| Sections | Topic | Lines |
|----------|-------|-------|
| §1 Principles | Guiding philosophy, domain language | 78–110 |
| §2–4 Project Setup | Structure, build, config | 111–293 |
| §5 Architecture | Layered architecture diagram | 294–340 |
| §6–10 Implementation | Controller, service, DAO, models, DTOs | 341–833 |
| §11 Shared Library | shared library modules, response flow | 834–924 |
| §12 Reactive | Mono/Flux rules, operator tree, anti-patterns | 925–1015 |
| §13–14 Java 21 & SOLID | Records, sealed types, pattern matching, SOLID | 1016–1384 |
| §15 Cloud-Native | 12-factor, health probes, graceful shutdown | 1385–1487 |
| §16 Error Handling | Exception hierarchy, reactive error patterns | 1488–1569 |
| §17–19 Infrastructure | Hazelcast, Couchbase, Kafka patterns | 1570–1760 |
| §20–23 Ops & Quality | Observability, security, testing, code quality | 1761–2138 |
| §24–25 API & Git | URL conventions, response envelope, versioning | 2139–2308 |
| Appendices | Naming, patterns, Java 21 matrix, new service checklist | 2309–2487 |

## Key Files

- `manifest.yaml` — Single source of truth. Defines all services, tech stack, build targets, and framework version
- `context/` — Business requirements, designs, references (human-maintained)
- `services/` — Per-service context and generated specs
  - `services/<name>/specs/SPEC.md` — Implementation specification (Phase 3)
  - `services/<name>/specs/TEST-PLAN.md` — Test cases with traceability (Phase 3)
  - `services/<name>/specs/BUILD-REPORT.md` — Build results (Phase 5)
  - `services/<name>/specs/TEST-REPORT.md` — Test execution results (Phase 5)
- `contracts/` — Shared API contracts between services
  - `contracts/CONTRACT-MATRIX.md` — Cross-service interface overview (Phase 4)
  - `contracts/INTEGRATION-TEST-PLAN.md` — Cross-service test scenarios (Phase 4)
- `standards/` — Coding standards, API design, and testing standards agents must follow
- `phases/` — Phase completion tracking

## Phase Workflow

Run phases in order using slash commands:

```
/project:0-setup       → Interactive project setup (run this first!)
/project:1-discover    → Analyze all context, ask clarifying questions
/project:2-architect   → Define service boundaries, data flow, tech decisions
/project:3-specify     → Generate detailed SPEC.md + TEST-PLAN.md per service
/project:4-contract    → Generate API contracts + INTEGRATION-TEST-PLAN.md
/project:5-build       → Build services with test traceability (per service)
/project:6-validate    → Cross-service integration validation
/project:7-review         → Code quality, security, test completeness review
/project:retrospective    → Post-iteration self-improvement (context, avoidances, gaps)
```

### Team Orchestration Commands

```
/project:team-start    → Spawn 5-agent team, auto-orchestrate Phases 1-7
/project:team-migrate  → Upgrade v1 repo to team-capable (v2.0)
/project:team-status   → Enhanced dashboard with agent assignments & test coverage
```

## Ask, Don't Assume Principle

Agents MUST NOT make assumptions about the project. When in doubt, ASK the human.

**Ask & Remember**:
1. **ASK** the human in a clear, guided way (offer options, suggest defaults)
2. **WRITE** the answer to the correct file immediately (manifest.yaml, CONTEXT.md, standards, etc.)
3. **NEVER** ask the same question twice — check what's already configured first

This applies to: project setup, build paths, service configuration, standards, and any other configuration that can be persisted. If the human says "not sure yet" or "defaults are fine", record a sensible default and move on.

**Never Assume — Always Verify**:
- **PII classification**: ASK the human which fields are PII. Business identifiers (orderId, userId, accountId) are often NOT PII. Don't restrict logging levels based on assumptions.
- **Security sensitivity**: ASK before adding encryption, hashing, or masking to data fields. Present your suggestion with rationale and let the human decide.
- **Tech stack choices**: CHECK `manifest.yaml → tech_stack` and existing services before proposing libraries. If the project uses Hazelcast, don't propose Caffeine.
- **UI design**: CHECK Figma designs before specifying component layout. Don't assume pills when the design shows line items.
- **API response structure**: VERIFY actual API responses (via curl or tests) before writing deserialization DTOs. Don't assume flat arrays when the API wraps in envelopes.
- **Environment config**: CHECK config repos and sibling services before assuming how auth, SSL, or discovery works.

**When to suggest vs ask**: Present your recommendation with rationale ("I suggest X because Y"), but explicitly ask for confirmation before implementing anything that affects security, data classification, or architecture.

## Rules for All Agents

- ALWAYS read `manifest.yaml` first — it drives everything
- NEVER modify files in `context/references/` — that's human-provided input
- `context/PROJECT.md` can be written by the setup agent (Phase 0) and read by all other agents
- `context/decisions/` can be written by the architect agent (Phase 2)
- ALWAYS write specs and test plans to `services/<name>/specs/` — never inline in other files
- ALWAYS generate TEST-PLAN.md alongside SPEC.md in Phase 3 — follow `standards/testing-standards.md`
- ALWAYS generate TEST-REPORT.md alongside BUILD-REPORT.md in Phase 5 — map tests to test case IDs
- ALWAYS generate contracts to `contracts/` — shared across services
- ALWAYS build code to the service's `local_path` defined in `manifest.yaml` — if not set, ASK the human for the path and save it back to the manifest. NEVER write service code inside this planning repo
- Respect `status` field: skip services marked `skip`, reference `existing` services, only build `new` and `enrich`
- Respect `build_targets` in manifest — if set, only work on listed services
- Follow standards in `standards/` for all generated code
- Write phase completion markers to `phases/` after each phase
- Check prerequisites before running any phase — read the required phase files in `phases/` first
- When a slash command receives arguments (available as `$ARGUMENTS`), parse them to determine the target service or options
- For large reference files (PDFs > 10 pages, long confluence docs), summarize key points rather than trying to read everything — prioritize business rules, API specs, and data models over general prose
- When reading `manifest.local.yaml` for local_path overrides, fall back to `manifest.yaml` if the local file doesn't exist
