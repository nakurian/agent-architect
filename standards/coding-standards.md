# Coding Standards

## Backend: Java / Spring Boot

**All backend code MUST follow [`backend-system-design-standard.md`](./backend-system-design-standard.md)** — the comprehensive backend standard.

Key points for agents:
- **Java 21** · Spring Boot 3.4+ · Spring WebFlux (reactive, Netty) — NOT Spring MVC
- **Couchbase** for persistence, **Hazelcast** for distributed cache, **Kafka** for messaging
- **Gradle with Kotlin DSL** (`build.gradle.kts`)
- **Shared library**: Configurable via `manifest.yaml → tech_stack.shared_library` (core, database, cache, messaging, iam, util modules)
- **Reactive-first**: All I/O returns `Mono<T>` / `Flux<T>`. Never `.block()` in production code.
- **Response envelope**: `ApiResponse<T>` from shared library (not a custom envelope)
- **Controllers** extend `BaseController` or `SecureController`
- **DAOs** extend `HazelcastService<K,V>` when caching is needed
- **Package-by-layer**: `controller/ → service/ → dao/ → persistence/`
- **Testing**: JUnit 5 + Mockito + StepVerifier + WebTestClient, 80% coverage
- **Code quality**: Spotless + Checkstyle (Google style, 0 violations) + JaCoCo

Refer to the full standard for detailed patterns, code examples, and anti-patterns.

---

## Frontend: React / TypeScript

### Project Structure

```
src/
├── app/                               # Next.js App Router or root layout
│   ├── layout.tsx                     # Root layout with AppShell
│   ├── page.tsx                       # Default page / redirect
│   └── {feature}/                     # Feature routes
│       └── page.tsx
├── features/                          # Feature-based modules
│   └── {feature}/
│       ├── {Feature}Page.tsx          # Page-level component
│       ├── {SubComponent}.tsx         # Feature-specific components
│       └── hooks/
│           └── use{Feature}.ts        # React Query hooks
├── shared/
│   ├── components/                    # Reusable components
│   ├── api/                           # Typed API client
│   ├── hooks/                         # Shared hooks
│   └── types/                         # TypeScript types matching API contracts
└── styles/
    └── theme.ts                       # Theme configuration
```

### Coding Conventions

- Use **TypeScript strict mode** — no `any` types
- Use **functional components** with hooks exclusively
- Use **React Query (TanStack Query)** for all server state — no manual fetch + useState
- Co-locate hooks with their feature: `features/{name}/hooks/use{Name}.ts`
- Use **Zod** schemas for runtime validation of API responses
- Prefer named exports over default exports

### Testing

- Unit tests for utility functions and hooks
- Component tests with React Testing Library
- E2E tests with Playwright

### Security

- Role-based access control via OAuth2 / SSO
- Same auth provider as other internal tools

### UI Behaviors

- Polling for real-time data updates (React Query `refetchInterval`)
- Optimistic updates for toggle operations
- Confirmation dialogs for all destructive/override actions
- Deep-linkable URLs for bookmarking and sharing

---

## Error Handling (all code)

- Use typed exceptions (`ValidationException` from shared library) — never raw `RuntimeException`
- Never expose stack traces or internal details in API responses
- Log the full error internally, return a safe `userMessage` externally
- Include `traceId` in all error responses (automatic via `ResponseFactory`)
- In reactive chains, prefer `Mono.error()` over `throw` — throwing breaks the pipeline
- Use `switchIfEmpty(Mono.error(...))` for "not found" patterns
- Use `onErrorResume()` for type-specific error recovery (e.g., `DocumentNotFoundException` → `Mono.empty()`)
- Fail fast on invalid input — validate at the controller boundary, not deep in service layer

## Testing (all code)

- Minimum **80%** instruction and branch coverage (JaCoCo enforced)
- Name tests descriptively: `methodName_condition_expectedResult` (e.g., `saveUser_success`, `findById_notFound_returnsEmpty`)
- Use test fixtures/factories (`TestUtils`) for test data — not inline object literals
- Use **StepVerifier** for all reactive `Mono`/`Flux` assertions
- Use **WebTestClient** for controller integration tests (`@WebFluxTest`)
- Use `@Nested` classes to group related test scenarios
- Excluded from coverage: annotations, config, DTOs, exceptions, persistence models, serializers, App.class

## Database / Data Access (all code)

- Use transactions (`TransactionalRunner`) for multi-step writes — never partial commits
- Use parameterized queries for all N1QL — never concatenate user input
- Index frequently queried fields (SORTED for range queries, HASH for equality lookups)
- Configure timeouts per query — different operations have different SLAs
- Use cache-first strategy: check Hazelcast → miss → fetch from database → populate cache
- DAOs never call other DAOs — service layer orchestrates multi-DAO operations
- Use soft deletes (`is_active` flag) where business requires audit trail
- Always set TTL on documents to prevent unbounded storage growth

## Security (all code)

- Validate and sanitize all inputs at the boundary (Jakarta Bean Validation)
- Use parameterized queries — never string concatenation for N1QL or SQL
- Implement rate limiting on public endpoints
- Use OAuth2 / JWT for auth (service-to-service via API gateway)
- Never log secrets (tokens, passwords, API keys). For other identifiers, ASK the human what's sensitive — don't assume.

## Observability (all code)

- Structured JSON logging via SLF4J + Log4j2
- Include correlationId (traceId), service name, and timestamp in every log
- Log at appropriate levels: ERROR for failures, WARN for degraded, INFO for business events, DEBUG for troubleshooting
- Expose `/adm/actuator/health` (liveness + readiness probes) and `/adm/actuator/prometheus`
- Emit metrics for: request count, latency, error rate, queue depth, business event counts

### Logging Standards — Production Grade (BINDING)

Every service method that makes external calls or handles business logic MUST have:

| Level | When | What to include | What to NEVER include |
|-------|------|-----------------|----------------------|
| INFO | Business events: operation start/complete, cache hit/miss | Operation name, timing (durationMs), counts, business IDs | Secrets (tokens, passwords, API keys) |
| DEBUG | Request/response details, intermediate state | Full payloads, cache keys, all identifiers | Secrets (tokens, passwords, API keys) |
| WARN | Recoverable issues, degraded operation | Warning context, fallback used | — |
| ERROR | All failures, timeouts, connection errors | Error type, status code, response body, exception message, stack trace, correlation IDs | Secrets (tokens, passwords, API keys) |

**PII Classification — ASK, Don't Assume**: Business identifiers (orderId, userId, accountId, bookingId) are often NOT PII. Before restricting any field from log levels, ASK the human which fields are truly sensitive. Only universally sensitive data (SSN, credit card numbers, passwords, auth tokens) should be restricted by default. Log what is needed for production troubleshooting.

**Critical Rule**: Every `onErrorResume()`, `catch`, or error recovery path MUST:
1. Log at ERROR level with full exception context (pass exception as last parameter for stack trace)
2. Include correlation IDs (traceId, messageId) for distributed tracing
3. NEVER swallow exceptions silently — the user gets graceful degradation, ops sees the real error

## General Principles (all code)

- Write clean, readable code over clever code
- Follow SOLID principles
- Prefer composition over inheritance
- Keep methods small and single-purpose (max ~30 lines)
- Use meaningful names — code should read like prose
- Use project domain terminology consistently (define in Phase 0 setup)

## Git & PR Conventions

- Branch naming: `feature/{ticket}-{description}`, `fix/{description}`, `hotfix/{description}`
- Commit messages: conventional commits (`feat:`, `fix:`, `chore:`, `docs:`, `test:`, `refactor:`)
- PRs must include: description, test plan, and link to spec
