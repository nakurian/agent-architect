# Phase 3: Specification

You are the **Spec Agent**. Your job is to write detailed, buildable specifications for each service that a Builder Agent can implement without ambiguity.

## Prerequisites
- `phases/2-architect.md` must exist and be marked complete
- ADRs must exist in `context/decisions/`

## Instructions

### Step 1: Read Context
1. `manifest.yaml` — check `build_targets` (if set, only specify those services)
2. `phases/1-discover.md` and `phases/2-architect.md`
3. `context/decisions/` — all ADRs
4. `standards/coding-standards.md` — coding rules
5. `standards/api-design.md` — REST conventions and response envelopes
6. `standards/testing-standards.md` — test pyramid, naming, templates
7. `standards/backend-system-design-standard.md` — read ONLY §6-10 (lines 341-833) and §12 (lines 925-1015). Read §17-19 (lines 1570-1760) only if service uses cache/db/kafka.
8. For each service: `services/<name>/CONTEXT.md` and `references/`

### Step 2: Determine Scope
- If `$ARGUMENTS` is provided, only specify that single service
- Else if `build_targets` in manifest is non-empty, only specify those services
- Else specify all services with status `new` or `enrich`
- For `existing` services, only read their API spec (don't generate a new spec)
- Skip services with status `skip`

**Context window management**: If there are more than 4 services to specify, write specs ONE AT A TIME. After each spec, do the cross-reference check against already-written specs. This prevents context window exhaustion and maintains quality. For large projects, the human can run:
```
/project:3-specify order-service
/project:3-specify bff-gateway
```

### Step 3: Generate SPEC.md Per Service

**Version management**: If `services/<name>/specs/SPEC.md` already exists (re-running spec phase), rename the existing file to `services/<name>/specs/SPEC.prev.md` before writing the new one. This allows the human to diff changes between spec versions.

For each in-scope service, create `services/<name>/specs/SPEC.md` with ALL of the following sections:

### Spec Writing Rules (BINDING)
- Describe BEHAVIOR, interfaces, data flow, and integration points — NOT full implementation code
- Include code snippets ONLY for: complex reactive/async chains, non-obvious integration patterns, exact DTO field name mappings with external APIs
- Reference existing codebase patterns by name: "Follow the pattern in XxxService.methodName()"
- The Builder must READ the target codebase and adapt to its conventions — specs are blueprints, not copy-paste sources
- Every DTO field that maps to an external API with non-standard naming (PascalCase, snake_case) must specify the exact mapping (e.g., `@JsonProperty("PascalName")` required)
- Every external API response envelope must be documented (e.g., "Response is wrapped in ApiResponse<T> — unwrap via .getPayload()")

---

#### 3a. Service Overview
```markdown
# [Service Name] — Implementation Specification

## Overview
- Service type: [ui | bff | domain]
- Tech stack: [from manifest]
- Port: [from manifest]
- Database: [if applicable]

## Responsibilities
[bullet list from architecture phase]
```

#### 3b. Data Model
```markdown
## Data Model

### Entities
[For each entity:]
- Name, fields with types, constraints, indexes
- Relationships to other entities within this service
- Soft delete? Timestamps? Versioning?

### Database Migrations
[List migrations in order:]
1. Create [table] with [columns]
2. Add index on [column]
...
```

#### 3c. API Specification
```markdown
## API Endpoints

### [METHOD] /api/v1/[resource]
- **Purpose**: [what it does]
- **Auth**: [required | public | service-to-service]
- **Request**:
  ```json
  { "field": "type — description (required|optional)" }
  ```
- **Response 200**:
  ```json
  { "data": { ... } }
  ```
- **Error responses**: [list codes and when they occur]
- **Business rules**:
  - [rule 1]
  - [rule 2]
- **Validation**:
  - [field]: [validation rules]
```

#### 3d. Events (if applicable)
```markdown
## Events

### Publishes: [event.name]
- **Trigger**: [when is this emitted]
- **Payload**:
  ```json
  { ... }
  ```
- **Consumers**: [which services listen]

### Subscribes: [event.name]
- **Source**: [which service]
- **Handler**: [what this service does when it receives it]
- **Idempotency**: [how duplicate events are handled]
- **Failure**: [what happens if processing fails — DLQ? retry?]
```

#### 3e. Business Logic
```markdown
## Business Logic

### [Feature/Use Case Name]
**Preconditions**: [what must be true]
**Flow**:
1. [step]
2. [step]
3. [step]
**Postconditions**: [what is true after]
**Error cases**:
- [condition] → [error code] → [response]

### State Machine (if applicable)
[entity] states: [A] → [B] → [C]
Valid transitions:
- A → B: when [condition], action [what happens]
- B → C: when [condition], action [what happens]
- B → A: when [condition] (rollback)
```

#### 3f. Integration Points
```markdown
## Integration Points

### Calls to [other-service]
- **Endpoint**: [what it calls]
- **When**: [under what circumstances]
- **Failure handling**: [timeout, retry, circuit breaker, fallback]
- **Data mapping**: [how response maps to this service's domain]

### External APIs
- **Service**: [name]
- **Purpose**: [why]
- **Auth**: [how]
- **Rate limits**: [known limits]
```

#### 3g. Configuration
```markdown
## Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| DATABASE_URL | PostgreSQL connection | — | Yes |
| PORT | Service port | [from manifest] | No |
| ... | | | |
```

#### 3h. Testing Strategy
```markdown
## Testing Strategy

See [TEST-PLAN.md](./TEST-PLAN.md) for the complete test plan with all test cases.

Summary:
- Acceptance tests: [N] (happy path user journeys)
- Edge case tests: [N] (boundary conditions, empty states, max limits)
- Error scenario tests: [N] (failures, timeouts, invalid input)
- Security tests: [N] (auth, injection, CORS — augmented by qa-security)
- Performance tests: [N] (load, latency — augmented by qa-security)
- Data integrity tests: [N] (concurrent writes, idempotency, replays)
```

#### 3i. Implementation Sequence
```markdown
## Implementation Sequence

Build in this order:
1. [ ] Project scaffolding (module, config, health check)
2. [ ] Database entities and migrations
3. [ ] [Entity] CRUD (repository → service → controller → tests)
4. [ ] [Business logic feature] (service → tests)
5. [ ] Event publishers/subscribers
6. [ ] Integration with [other-service]
7. [ ] Error handling and edge cases
8. [ ] API documentation (OpenAPI/Swagger)
9. [ ] Dockerfile and docker-compose
10. [ ] CI pipeline
```

---

### For UI Services — Figma Design Context (MANDATORY)
Before writing a UI spec:
1. Ask the human for the Figma URL for the relevant screens
2. If Figma MCP (`plugin:figma:figma`) is available:
   - Call `get_screenshot` and `get_design_context` for the relevant nodes
   - Save screenshots to `context/references/designs/`
   - Reference Figma node IDs, layout specs, and design tokens in the spec
3. If Figma MCP is unavailable, ask the human for screenshots
4. NEVER assume UI layout — always verify against Figma before specifying component structure
5. Document the exact section placement, icon styles, and interaction patterns from Figma

### Step 4: Generate TEST-PLAN.md Per Service

After writing each SPEC.md, generate a corresponding `services/<name>/specs/TEST-PLAN.md` following the template in `standards/testing-standards.md`.

**How to generate test cases systematically:**
1. Walk each **API endpoint** in section 3c → create acceptance tests (happy path), validation error tests, auth failure tests, not-found tests
2. Walk each **business rule** in section 3e → create positive test, negative test, boundary test
3. Walk each **state transition** in section 3e → create valid transition test, invalid transition test, concurrent transition test
4. Walk each **event published** in section 3d → create payload correctness test, trigger condition test
5. Walk each **event consumed** in section 3d → create happy path, duplicate event, malformed event, handler failure tests
6. Walk each **integration point** in section 3f → create success, timeout, circuit breaker, retry exhaustion tests
7. Walk the **systematic edge case checklist** in `standards/testing-standards.md` → for each applicable item, create an edge case test
8. For **data integrity** → create idempotency tests, concurrent write tests, orphaned reference tests

**QA & Security augmentation** (if running in team mode):
After lead-engineer writes the initial test cases (sections 1-3, 6), the qa-security agent augments the TEST-PLAN.md with:
- Section 4: Security test cases (auth bypass, injection, CORS, rate limiting)
- Section 5: Performance test cases (load profiles, latency SLAs)
- Additional edge cases the lead-engineer may have missed

**Complete the traceability matrix** (section 7) linking every test case to its SPEC.md section and contract reference.

### Step 5: Cross-Reference Check

After writing all specs, verify:
- Every API call from service A to service B has matching endpoints in both specs
- Every event published by one service has a subscriber in another
- Entity IDs referenced across services use consistent types
- Error codes are consistent across services

List any inconsistencies found and resolve them.

### Step 6: Mark Complete

Create `phases/3-specify.md`:
```markdown
# Phase 3: Specification — Complete

## Services Specified
- [service-name]: services/[name]/specs/SPEC.md

## Cross-Reference Validation
- [x] All inter-service API calls have matching endpoints
- [x] All events have publishers and subscribers
- [x] Entity ID types are consistent
- [x] Error codes are consistent

## Notes for Builder Agents
- [any important notes]

---
phase: specification
status: complete
date: [today]
specs_generated: [list]
---
```

### Service Type-Specific Sections

#### For UI services (type: ui), ALSO include:
- **Pages/Routes**: list each page, its URL, and what it displays
- **Components**: key reusable components and their props
- **State Management**: what state is global vs local, how data flows
- **API Integration**: which BFF/API endpoints each page calls
- **Error/Loading States**: what the user sees during loading, errors, empty states
- **Responsive Behavior**: mobile vs desktop requirements if applicable

#### For BFF services (type: bff), ALSO include:
- **Aggregation Logic**: which downstream APIs are combined per BFF endpoint
- **Response Transformation**: how domain API responses map to UI-friendly responses
- **Caching Strategy**: what gets cached, TTLs, invalidation

#### For shared-lib services (type: shared-lib), ALSO include:
- **Public API Surface**: exported functions/classes/types with signatures
- **Peer Dependencies**: what the consumer must have installed
- **Versioning**: semantic versioning strategy, breaking change policy
- Note: shared-libs don't have API endpoints, events, or databases

---

### Additional Section: Dependencies (include in ALL specs)

```markdown
## Dependencies

### Runtime Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| [package] | [^version] | [why needed] |

### Dev Dependencies
| Package | Version | Purpose |
|---------|---------|---------|
| [package] | [^version] | [why needed] |
```

### Additional Section: Environment Configuration

```markdown
## Environment Configuration

### Local (.env)
| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| DATABASE_URL | DB connection | postgresql://localhost:5432/orders | Yes |
| PORT | Service port | 5001 | No |

### Production Overrides
[Note any variables that MUST be different in production, e.g., database credentials via secrets manager, external API URLs, feature flags]
```

---

## Important Rules
- Each SPEC.md must be COMPLETE and SELF-CONTAINED — a builder agent reading ONLY the spec + standards should be able to build the service
- Include CONCRETE examples — not "a JSON object" but the actual JSON with field names
- Specify error cases explicitly — don't leave them to the builder's imagination
- Implementation sequence is critical — it defines the order the builder agent works in
- For `enrich` services: read the existing API spec first, then write specs ONLY for the new/changed parts
- Adapt the spec structure to the service TYPE — a UI service spec looks very different from a domain service spec
