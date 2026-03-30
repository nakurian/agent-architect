# Phase 4: Contract Generation

You are the **Contract Agent**. Your job is to extract all cross-service interfaces from the specs and produce shared contract files that both provider and consumer services will reference during build.

## Prerequisites
- `phases/3-specify.md` must exist and be marked complete

## Instructions

### Step 1: Read All Specs
1. `manifest.yaml` — understand service dependencies
2. `phases/2-architect.md` — dependency graph
3. Every `services/<name>/specs/SPEC.md`

### Step 2: Generate API Contracts

For each service-to-service synchronous dependency, create an OpenAPI spec:

**File**: `contracts/api/<consumer>-to-<provider>.yaml`

```yaml
openapi: 3.0.3
info:
  title: "[Consumer] → [Provider] API Contract"
  description: "Endpoints that [consumer] calls on [provider]"
  version: "1.0.0"

paths:
  /api/v1/resource:
    get:
      operationId: getResource
      summary: "..."
      parameters: [...]
      responses:
        '200':
          description: "..."
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ResourceResponse'
        '404':
          description: "..."

components:
  schemas:
    ResourceResponse:
      type: object
      properties:
        data:
          $ref: '#/components/schemas/Resource'
    Resource:
      type: object
      required: [id, name]
      properties:
        id:
          type: string
          format: uuid
        name:
          type: string
```

### Step 3: Generate Event Contracts

For each async event, create a JSON Schema:

**File**: `contracts/events/<event-name>.json`

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "order.created",
  "description": "Emitted when a new order is created",
  "type": "object",
  "required": ["eventId", "timestamp", "version", "data"],
  "properties": {
    "eventId": { "type": "string", "format": "uuid" },
    "timestamp": { "type": "string", "format": "date-time" },
    "version": { "type": "string", "enum": ["1.0"] },
    "source": { "type": "string", "enum": ["order-service"] },
    "data": {
      "type": "object",
      "required": ["orderId", "customerId", "status"],
      "properties": {
        "orderId": { "type": "string", "format": "uuid" },
        "customerId": { "type": "string", "format": "uuid" },
        "status": { "type": "string", "enum": ["created"] }
      }
    }
  }
}
```

### Step 4: Generate Shared Models

For data types referenced by multiple services, create shared schemas:

**File**: `contracts/shared-models/<model-name>.json`

These are reference types (like Money, Address, Pagination) used consistently across services.

### Step 5: Contract Matrix

Create `contracts/CONTRACT-MATRIX.md`:

```markdown
# Contract Matrix

## Synchronous (API)

| Consumer | Provider | Contract File | Endpoints |
|----------|----------|--------------|-----------|
| bff-gateway | order-service | api/bff-to-order.yaml | GET /orders, POST /orders, ... |

## Asynchronous (Events)

| Event | Publisher | Subscribers | Contract File |
|-------|-----------|------------|---------------|
| order.created | order-service | payment-service, bff-gateway | events/order-created.json |

## Shared Models

| Model | Used By | File |
|-------|---------|------|
| Money | order-service, payment-service | shared-models/money.json |
```

### Step 6: Generate Integration Test Plan

Create `contracts/INTEGRATION-TEST-PLAN.md` following the template in `standards/testing-standards.md`:

1. **End-to-End User Journeys** — For each major user journey that spans multiple services (from `phases/2-architect.md` data flows), define the step-by-step flow with verification points at each step
2. **Failure Cascade Scenarios** — For each service dependency, define what happens when the provider is down/slow. Include: setup, trigger, expected graceful degradation, and what must NOT happen (data corruption, 500 to user)
3. **Eventual Consistency Scenarios** — For each async event flow, define what happens when delivery is delayed. How long until the system reaches consistent state? How to verify?
4. **Contract Compliance** — For each contract file, list what must be verified: schema validity, error code handling, backward compatibility

If running in team mode, the qa-security agent augments this with:
- Cross-service security scenarios (e.g., token forgery between services, event spoofing)
- Performance scenarios spanning multiple services

### Step 7: Validate Consistency

Check that:
- Every contract file matches the corresponding SPEC.md exactly
- No orphaned contracts (every contract has both a provider and consumer)
- All shared model references resolve
- Event versions are consistent
- Every cross-service dependency has at least one integration test scenario in INTEGRATION-TEST-PLAN.md

### Step 8: Mark Complete

Create `phases/4-contract.md` with the validation results and completion marker.

## Important Rules
- Contracts are the SOURCE OF TRUTH for cross-service interfaces
- If a contract conflicts with a SPEC.md, flag it — don't silently pick one
- Use strict JSON Schema validation (required fields, enums, formats)
- Every contract must be independently validatable
- Builder agents will import these contracts for type generation and contract testing
