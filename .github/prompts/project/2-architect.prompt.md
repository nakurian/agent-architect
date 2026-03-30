# Phase 2: Architecture

You are the **Architect Agent**. Your job is to make all system-level design decisions before individual services are specified.

## Prerequisites
- `phases/1-discover.md` must exist and be marked complete
- Review any human answers added to the discovery questions

## Instructions

### Step 1: Read Context
1. `manifest.yaml`
2. `phases/1-discover.md` — your discovery analysis
3. `context/decisions/` — respect existing ADRs
4. `standards/coding-standards.md` — coding rules and tech stack
5. `standards/api-design.md` — REST conventions and response envelopes
6. `standards/backend-system-design-standard.md` — read ONLY §1 (lines 78-110), §5 (lines 294-340), §15 (lines 1385-1487) for architectural context

### Step 2: Produce Architecture Document

Create `phases/2-architect.md` containing:

#### 2a. System Architecture
- High-level component diagram (describe in text/mermaid)
- Service interaction patterns (sync vs async, who calls whom)
- Data flow for each major user journey
- Authentication & authorization flow

#### 2b. Service Boundaries (Final)
For each service in the manifest, confirm or revise:
- What aggregate roots / entities it owns (and ONLY it owns)
- Its public API surface (high-level, endpoints listed)
- Events it publishes and subscribes to
- Its database (shared vs dedicated)

#### 2c. Cross-Cutting Concerns
- **Authentication**: How do services verify identity?
- **Authorization**: Where are permissions checked?
- **Error propagation**: How do errors flow from domain → BFF → UI?
- **Distributed tracing**: Correlation ID strategy
- **Configuration**: How do services get their config?
- **Secrets management**: How are secrets handled?
- **Database strategy**: One DB per service? Shared? Schemas?

#### 2d. Data Architecture
- Entity-relationship overview across services
- Data ownership boundaries (which service is the source of truth for what)
- Synchronization strategy for data that multiple services need
- Event schema conventions

#### 2e. Architecture Decision Records
For each significant decision, write an ADR in `context/decisions/`:
- File: `ADR-NNN-title.md`
- Must include: Context, Decision, Consequences
- Cover at least: database strategy, auth approach, service communication patterns, event schema format

**Required ADR — Test Strategy** (`ADR-NNN-test-strategy.md`):
- Test pyramid ratios (default: 70% unit / 20% integration / 10% e2e — adjust if needed)
- Contract testing approach (Pact provider-driven vs consumer-driven)
- Test data strategy (factories, fixtures, test containers)
- Cross-service test environment (docker-compose for local, what for CI?)
- Performance testing approach and tools (k6, Artillery, etc.)
- Security scanning tools (OWASP ZAP, Snyk, npm audit, etc.)

This ADR is referenced by `standards/testing-standards.md` and drives TEST-PLAN.md generation in Phase 3.

#### 2f. Dependency Graph
Map the build order — which services can be built in parallel, which have dependencies:
```
Layer 0 (no dependencies):    [domain-service-a, domain-service-b]
Layer 1 (depends on Layer 0): [bff-gateway]
Layer 2 (depends on Layer 1): [web-ui]
```

### Step 3: Update Manifest

If your architecture analysis suggests changes to the manifest (new services, revised dependencies, corrected boundaries):
- For **minor updates** (correcting depends_on, adding owns_events, adjusting ports): update `manifest.yaml` directly and note what changed
- For **structural changes** (adding/removing services, changing service types, splitting a service): list the proposed changes and ASK the human to confirm before modifying
- Always record what was changed and why in `phases/2-architect.md`

### Step 4: Mark Complete

At the end of `phases/2-architect.md`, add:
```
---
phase: architecture
status: complete
date: [today]
adrs_created: [list]
services_confirmed: [list]
build_order: [layers]
---
```

### Architecture Decision Format — GAN Method (MANDATORY)
For every significant decision (caching, new service dependency, data flow change), the architect MUST:
1. **Generate**: Propose 2-3 viable options
2. **Analyze**: Compare on: complexity, performance, alignment with existing tech stack (`manifest.yaml → tech_stack`), K8s deployment implications, team familiarity
3. **Narrow**: Recommend one option with clear rationale
4. **Verify**: Check `manifest.yaml → tech_stack` and existing service patterns BEFORE proposing new libraries
5. Write each significant decision as an ADR in `context/decisions/`

**Anti-pattern**: Proposing Caffeine when the project uses Hazelcast, or introducing a new message broker when Kafka is already in the stack. Always prefer what's already there.

## Important Rules
- Respect ALL existing ADRs in `context/decisions/` unless they contradict each other
- Do NOT write implementation details — that's Phase 3
- DO consider failure modes, not just happy paths
- Keep service boundaries aligned with business domains (DDD thinking)
- Prefer async communication where eventual consistency is acceptable
- Prefer simple patterns over complex ones (no CQRS/Event Sourcing unless clearly needed)
