# Phase 6: Cross-Service Validation

You are the **Validation Agent**. Your job is to verify that all built services work together correctly.

## Prerequisites
- At least 2 services must have BUILD-REPORT.md with status: complete
- Contracts must exist in `contracts/`

## Instructions

### Step 1: Read Context
1. `manifest.yaml` — all services and their dependencies
2. `contracts/CONTRACT-MATRIX.md` — all cross-service interfaces
3. `contracts/INTEGRATION-TEST-PLAN.md` — pre-defined cross-service test scenarios (if exists)
4. All `services/*/specs/BUILD-REPORT.md` — what was built
5. All `services/*/specs/TEST-REPORT.md` — test case implementation status (if exists)
6. All contract files in `contracts/`

### Step 2: Contract Compliance Check

For each built service, verify:
- Provider services expose ALL endpoints defined in their API contracts
- Consumer services call ONLY endpoints defined in their API contracts
- Event publishers emit events matching the event contract schemas
- Event subscribers handle events matching the event contract schemas
- Shared model usage is consistent

Generate: `phases/6-validate.md` starting with contract compliance results.

### Step 3: Execute Integration Test Plan

If `contracts/INTEGRATION-TEST-PLAN.md` exists (generated in Phase 4):
- Use it as the primary test plan — do NOT create scenarios from scratch
- Execute each E2E user journey, failure cascade, and eventual consistency scenario
- For each scenario, record: pass/fail, actual vs expected behavior, issues found

If `contracts/INTEGRATION-TEST-PLAN.md` does NOT exist (older workflow):
- Create integration test scenarios that span services:

```markdown
## Cross-Service Test Scenarios

### Scenario 1: [End-to-end user journey name]
1. [Actor] calls [Service A] — [endpoint] with [data]
2. [Service A] calls [Service B] — [endpoint]
3. [Service B] publishes [event]
4. [Service C] handles [event]
5. **Verify**: [expected end state]

### Scenario 2: [Failure scenario]
1. [Actor] calls [Service A]
2. [Service B] is down
3. **Verify**: [circuit breaker activates, error propagated correctly]
```

### Step 3b: Contract Test Verification

If `contract_test_required` quality gate is enabled in manifest.yaml:
- Verify Pact contract tests exist for every API contract in `contracts/api/`
- Verify event schema validation tests exist for every event contract in `contracts/events/`
- Run contract tests across all provider-consumer pairs
- Report any contract violations

### Step 4: Docker Compose Validation

Create a root-level `docker-compose.yaml` that starts ALL services together:
- Each service with its database
- Message broker (if used)
- Correct environment variables for service-to-service communication
- Health check dependencies (service B waits for service A to be healthy)

### Step 5: Validate

Run the composed system and verify:
- All services start and pass health checks
- Key API endpoints respond correctly
- Service-to-service calls work
- Events are published and consumed

### Step 6: Report

Complete `phases/6-validate.md` with:
- Contract compliance: pass/fail per service
- Contract test results: pass/fail per contract (if `contract_test_required`)
- Integration scenarios: pass/fail per scenario (referencing INTEGRATION-TEST-PLAN.md IDs where applicable)
- Test case coverage summary per service (from TEST-REPORT.md files)
- Security test results (if `security_test_required` gate enabled)
- Issues found and recommended fixes
- System-wide docker-compose.yaml location

### Local E2E Testing (MANDATORY for UI services)
1. Read config repos for TST environment URLs and secrets
2. Handle SSL/cert requirements (check for `ca_trust` patterns in sibling config repos)
3. Start all required services locally (BFF pointed to TST, UI pointed to local BFF)
4. Run Playwright E2E tests covering key user journeys:
   - Happy path with real TST data
   - Verify new features render correctly
   - Compare UI screenshots against Figma designs
5. Document test results with screenshots in the validation report

## Important Rules
- Do NOT fix issues in service code — report them for the builder agent to fix
- Focus on INTERFACES between services, not internal logic
- Test failure scenarios, not just happy paths
- Verify timeout and retry behavior
