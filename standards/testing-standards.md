# Testing Standards

All agents must follow these standards when creating test plans, writing tests, and reviewing test quality.

## Test Pyramid

Target ratio (adjust per project via ADR):
- **60% Unit tests** — fast, isolated, test single functions/methods (DAO, utilities, serializers, validators)
- **30% Service tests** — business logic, reactive chains, error handling (Mockito + StepVerifier)
- **10% Integration / E2E / Contract tests** — controller + validation + response shape, cross-service flows, Pact contract verification

## Framework Stack (Backend — Java)

| Tool | Purpose |
|------|---------|
| JUnit 5 | Test runner, `@Nested`, `@DisplayName`, `@ParameterizedTest` |
| Mockito | Mocking: `@Mock`, `@InjectMocks`, `when/thenReturn`, `verify` |
| StepVerifier | Reactive assertions for `Mono`/`Flux` |
| WebTestClient | Integration testing for WebFlux controllers |
| AssertJ | Fluent assertions (`assertThat(x).isEqualTo(y)`) |

## Naming Conventions

### Test Files (Backend — Java)
- Unit tests: `{ClassName}Test.java` (mirrors source package)
- Controller tests: `{ClassName}Test.java` with `@WebFluxTest`
- Service tests: `{ClassName}Test.java` with `@ExtendWith(MockitoExtension.class)`

### Test Files (Frontend — TypeScript)
- Unit tests: `<module>.spec.ts` (co-located with source)
- Integration tests: `<module>.integration.spec.ts` or in `test/` directory
- E2E tests: `test/e2e/<feature>.e2e.spec.ts`
- Contract tests: `test/contract/<consumer>-<provider>.pact.spec.ts`

### Test Names (Backend — Java)
Use the pattern: `methodName_condition_expectedResult`
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Nested
    class SaveOrder {
        @Test void saveOrder_success() {}
        @Test void saveOrder_invalidStartDate_throwsBadRequest() {}
        @Test void saveOrder_notFound_returnsEmpty() {}
    }
}
```

### Test Names (Frontend — TypeScript)
Use the pattern: `should <expected behavior> when <condition>`
```typescript
describe('OrderService', () => {
  describe('createOrder', () => {
    it('should create order with status PENDING when valid input provided', () => {});
    it('should throw ValidationError when startDate is invalid', () => {});
  });
});
```

### Test Case IDs
Every test case in TEST-PLAN.md uses the format: `TC-[SVC]-[TYPE]-[NNN]`
- `SVC` = service abbreviation (e.g., `ORD` for order-service, `PAY` for payment-service)
- `TYPE` = `ACC` (acceptance), `EDGE` (edge case), `ERR` (error), `SEC` (security), `PERF` (performance), `DATA` (data integrity), `INT` (integration)
- `NNN` = sequential number

Examples: `TC-ORD-ACC-001`, `TC-PAY-ERR-003`, `TC-BFF-SEC-001`

## Test Traceability

Every implemented test MUST reference the TEST-PLAN.md case(s) it covers:
```typescript
// Covers: TC-ORD-ACC-001
it('should create order with status PENDING when valid input provided', () => {});

// Covers: TC-ORD-EDGE-002, TC-ORD-EDGE-003
it('should reject order when amount exceeds MAX_ORDER_AMOUNT', () => {});
```

This enables automated coverage tracking in TEST-REPORT.md.

## Test Data Strategy

### Factories (Preferred)
Use factory functions for test data — not raw object literals repeated across tests:
```typescript
// test/factories/order.factory.ts
export const createOrderInput = (overrides?: Partial<CreateOrderDto>) => ({
  customerId: 'cust-123',
  items: [{ productId: 'prod-1', quantity: 1, price: 10.00 }],
  ...overrides,
});
```

### Database Tests
- Use transactions that rollback after each test (preferred) or truncate tables in `beforeEach`
- Never share database state between tests
- Use test containers (e.g., `testcontainers`) for CI environments
- Seed data explicitly in each test — don't rely on migration seed data

### External Service Mocks
- Mock external HTTP services at the network level (e.g., `nock`, `msw`) — not at the import level
- Mock message broker in unit tests; use real broker in integration tests
- Never mock the database in integration tests — use a real database instance

## Backend Test Patterns (Java / Spring Boot)

### Controller Test Pattern
```java
@WebFluxTest(OrderController.class)
@Import(TestConfig.class)
class OrderControllerTest {

    @Autowired private WebTestClient webTestClient;
    @MockBean private OrderService orderService;

    @Test
    void getOrder_success() {
        var response = OrderResponse.builder()
            .orderId("ORD-001")
            .build();

        when(orderService.getOrder("ORD-001")).thenReturn(Mono.just(response));

        webTestClient.get()
            .uri("/api/orders/ORD-001")
            .exchange()
            .expectStatus().isOk()
            .expectBody(new ParameterizedTypeReference<ApiResponse<OrderResponse>>() {})
            .consumeWith(result -> {
                var body = result.getResponseBody();
                assertThat(body.getPayload().getOrderId()).isEqualTo("ORD-001");
            });
    }
}
```

### Service Test Pattern
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock private OrderDAO orderDAO;
    @InjectMocks private OrderService orderService;

    @Test
    void getOrder_success() {
        var order = TestUtils.buildOrder("ORD-001");
        when(orderDAO.findById("ORD-001")).thenReturn(Mono.just(order));

        StepVerifier.create(orderService.getOrder("ORD-001"))
            .assertNext(response -> {
                assertThat(response.getOrderId()).isEqualTo("ORD-001");
            })
            .verifyComplete();
    }

    @Test
    void getOrder_notFound_returnsEmpty() {
        when(orderDAO.findById("ORD-001")).thenReturn(Mono.empty());

        StepVerifier.create(orderService.getOrder("ORD-001"))
            .verifyComplete();
    }
}
```

### Test Utilities
Create a shared `TestUtils` class per service:
```java
public final class TestUtils {
    private TestUtils() {}

    public static Order buildOrder(String orderId) {
        return Order.builder()
            .orderId(orderId)
            .startDate("20260318")
            .customerName("Test Customer")
            .status("PENDING")
            .build();
    }
}
```

### Coverage Requirements (Backend)
- **Minimum 80%** instruction coverage (JaCoCo)
- **Minimum 80%** branch coverage (JaCoCo)
- **Excluded from coverage**: annotations, config, DTOs, exceptions, persistence models, serializers, App.class

```kotlin
jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                counter = "INSTRUCTION"
                minimum = "0.80".toBigDecimal()
            }
            limit {
                counter = "BRANCH"
                minimum = "0.80".toBigDecimal()
            }
        }
    }
}
```

## Systematic Edge Case Checklist

Agents MUST walk through this checklist for every API endpoint and business rule when generating TEST-PLAN.md. Not every item applies to every endpoint — skip items with a note explaining why.

### Input Boundaries
- [ ] Empty string / null / undefined for each string field
- [ ] Maximum length string (at database column limit)
- [ ] Zero, negative, MAX_INT / MAX_SAFE_INTEGER for numeric fields
- [ ] Unicode characters, emoji, RTL text, HTML entities for string fields
- [ ] Past dates, future dates, epoch zero, invalid date formats for date fields
- [ ] Empty array, single-element array, array at maximum size for array fields
- [ ] Missing required fields
- [ ] Extra/unknown fields (should be stripped or rejected)
- [ ] Duplicate entries in arrays or unique-constrained fields

### State Boundaries
- [ ] Entity does not exist (404 scenario)
- [ ] Entity in unexpected state for the operation (e.g., cancelling an already-shipped order)
- [ ] Entity was soft-deleted
- [ ] Concurrent modification of the same entity (optimistic locking / version conflict)
- [ ] Entity at a state machine terminal state (no further transitions possible)

### Authentication & Authorization
- [ ] No token / missing Authorization header
- [ ] Expired token
- [ ] Malformed token (invalid JWT structure)
- [ ] Valid token but insufficient role/scope for the operation
- [ ] Token for a different tenant (multi-tenancy isolation)
- [ ] Service-to-service token used on a user endpoint (and vice versa)
- [ ] Token with revoked permissions

### Infrastructure Failures
- [ ] Database connection lost mid-transaction
- [ ] Message broker unavailable when publishing an event
- [ ] Downstream service returns 503 (circuit breaker activation)
- [ ] Request timeout on external call (slow dependency)
- [ ] Connection pool exhausted
- [ ] DNS resolution failure for external dependency
- [ ] Disk full (for file-writing operations)

### Data Integrity
- [ ] Idempotent operation replayed (same request ID sent twice)
- [ ] Event replayed (same event delivered twice — idempotent handler)
- [ ] Orphaned references (foreign key points to deleted entity in another service)
- [ ] Concurrent writes to the same entity (race condition)
- [ ] Partial failure in multi-step operation (e.g., payment charged but order creation failed)
- [ ] Data migration edge cases (old format data still in database)

## TEST-PLAN.md Template

Every service gets a `services/<name>/specs/TEST-PLAN.md` generated in Phase 3. Use this structure:

```markdown
# [Service Name] — Test Plan

## Metadata
- spec_version: [date or hash of SPEC.md this plan is based on]
- created_by: lead-engineer
- augmented_by: qa-security
- reviewed_by: [reviewer agent or human]
- status: draft | reviewed | approved

## 1. Business Acceptance Tests (Happy Path)

### TC-[SVC]-ACC-001: [User Journey Name]
- **Requirement**: [SPEC.md section reference, e.g., "Business Logic > Create Order"]
- **Preconditions**: [state that must exist before test]
- **Steps**:
  1. [action]
  2. [action]
- **Expected Result**: [observable outcome with specific values]
- **Priority**: P0 | P1 | P2
- **Type**: unit | integration | e2e

## 2. Edge Cases and Boundary Conditions

### TC-[SVC]-EDGE-001: [Description]
- **Requirement**: [SPEC.md section reference]
- **Boundary**: [which boundary from the checklist]
- **Input**: [exact input values]
- **Expected Result**: [specific error or behavior]
- **Priority**: P0 | P1 | P2

## 3. Error Scenarios

### TC-[SVC]-ERR-001: [Description]
- **Trigger**: [what causes the error]
- **Expected Behavior**: [HTTP status, error code, error message, side effects]
- **Recovery**: [how the system recovers, if applicable]
- **Priority**: P0 | P1 | P2

## 4. Security Test Cases

### TC-[SVC]-SEC-001: [Description]
- **Attack Vector**: [what is being tested, from OWASP or auth checklist]
- **Test Method**: [how to test it]
- **Expected Defense**: [what the service should do]
- **Priority**: P0 | P1

## 5. Performance Test Cases

### TC-[SVC]-PERF-001: [Description]
- **Scenario**: [load profile, e.g., "100 concurrent requests"]
- **SLA**: [latency p95 target, throughput target]
- **Measurement**: [how to measure]
- **Priority**: P1 | P2

## 6. Data Integrity Test Cases

### TC-[SVC]-DATA-001: [Description]
- **Scenario**: [concurrent write, idempotent replay, etc.]
- **Verification**: [how to verify data correctness after scenario]
- **Priority**: P0 | P1

## 7. Traceability Matrix

| Test Case ID | SPEC.md Section | Contract Reference | Priority | Type |
|---|---|---|---|---|
| TC-SVC-ACC-001 | Business Logic > Create Order | — | P0 | integration |
| TC-SVC-EDGE-001 | API > POST /orders | — | P1 | unit |
| TC-SVC-ERR-001 | Integration > payment-service | api/bff-to-order.yaml | P0 | integration |
```

## INTEGRATION-TEST-PLAN.md Template

Generated in Phase 4, lives at `contracts/INTEGRATION-TEST-PLAN.md`:

```markdown
# Cross-Service Integration Test Plan

## End-to-End User Journeys

### E2E-001: [Journey Name]
- **Services involved**: [list]
- **Steps**:
  1. [action] → [service] → [response/event]
  2. [action] → [service] → [response/event]
- **Verification points**: [what to assert at each step]
- **Data setup**: [seed data needed]
- **Priority**: P0 | P1

## Failure Cascade Scenarios

### FAIL-001: [Scenario Name]
- **Setup**: [which service is down/slow]
- **Trigger**: [user action]
- **Expected**: [graceful degradation behavior]
- **NOT expected**: [what must NOT happen — e.g., data corruption, 500 to user]

## Eventual Consistency Scenarios

### CONS-001: [Scenario Name]
- **Setup**: [e.g., message broker has 30s delivery delay]
- **Expected**: [system reaches consistent state within N seconds]
- **Verification**: [how to verify both services are in sync]

## Contract Compliance

For each contract file in `contracts/api/` and `contracts/events/`:
- Provider responds with schema-valid responses for all documented endpoints
- Consumer handles all documented error codes gracefully
- Event payloads match JSON Schema definitions
- Backward compatibility maintained (no breaking changes)
```

## TEST-REPORT.md Template

Generated in Phase 5, lives at `services/<name>/specs/TEST-REPORT.md`:

```markdown
# Test Report: [Service Name]

## Coverage
- Line coverage: [N]%
- Branch coverage: [N]%
- Function coverage: [N]%

## Test Case Coverage
- P0 cases implemented: [N of M] ([%])
- P1 cases implemented: [N of M] ([%])
- P2 cases implemented: [N of M] ([%])
- Total: [N of M] TEST-PLAN.md cases implemented

## Test Case Mapping

| Test Case ID | Test File:Line | Status | Notes |
|---|---|---|---|
| TC-ORD-ACC-001 | orders.controller.spec.ts:15 | PASS | |
| TC-ORD-EDGE-003 | orders.service.spec.ts:42 | PASS | |
| TC-ORD-SEC-001 | — | DEFERRED | Requires auth module from shared-lib |

## Unplanned Tests Added
[Tests the builder wrote that were not in TEST-PLAN.md — bugs discovered during implementation, etc.]

## Run Summary
- Total tests: [N]
- Passed: [N]
- Failed: [N]
- Skipped: [N]
- Duration: [N]s
```

## Quality Gates

| Gate | Threshold | Blocks |
|---|---|---|
| `test_coverage_minimum` | 80% line coverage | Phase 5 → Phase 6 |
| `test_case_coverage_minimum` | 95% of P0+P1 cases implemented | Phase 5 → Phase 6 |
| `test_plan_review` | Human/QA approval of TEST-PLAN.md | Phase 3 → Phase 5 |
| `contract_test_required` | Pact tests exist for every contract | Phase 5 → Phase 6 |
| `security_test_required` | All security test cases executed | Phase 6 → Phase 7 |
| `integration_test_required` | Cross-service scenarios pass | Phase 6 → Phase 7 |

## Priority Definitions

- **P0 (Critical)**: Must pass for production readiness. Business-critical happy paths, data integrity, authentication. All P0 tests MUST be implemented.
- **P1 (Important)**: Should pass. Edge cases, error handling, authorization, performance baselines. 95%+ of P1 tests should be implemented.
- **P2 (Nice to Have)**: Best effort. Rare edge cases, cosmetic error messages, extreme load scenarios. Implement as time allows.
