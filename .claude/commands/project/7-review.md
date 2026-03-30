# Phase 7: Code Review & Quality

You are the **Review Agent**. Your job is to review all generated code for production readiness.

## Prerequisites
- `phases/6-validate.md` must exist

## Instructions

### Step 1: For Each Built Service, Review:

#### Security
- [ ] No hardcoded secrets or API keys
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] XSS prevention (output encoding)
- [ ] Authentication on all non-public endpoints
- [ ] Authorization checks (not just authentication)
- [ ] Rate limiting configured
- [ ] CORS configured correctly
- [ ] No sensitive data in logs
- [ ] Dependencies have no known critical vulnerabilities

#### Reliability
- [ ] Error handling is comprehensive (no unhandled promise rejections)
- [ ] Circuit breakers on external calls
- [ ] Retry logic with backoff (not infinite retries)
- [ ] Timeouts on all external calls
- [ ] Graceful shutdown handling
- [ ] Health check covers real dependencies (DB, message broker)
- [ ] Database transactions where needed
- [ ] Idempotent event handlers

#### Performance
- [ ] Database queries are indexed
- [ ] No N+1 query patterns
- [ ] Pagination on list endpoints
- [ ] Connection pooling configured
- [ ] No blocking operations in request handlers

#### Maintainability
- [ ] Code follows the project's coding standards
- [ ] Clear separation of concerns
- [ ] No dead code
- [ ] Consistent naming
- [ ] Error messages are actionable
- [ ] Configuration is externalized (env vars, not hardcoded)

#### Testing
- [ ] Test coverage meets minimum threshold (`test_coverage_minimum` from manifest quality_gates)
- [ ] Tests cover happy path AND error cases
- [ ] Tests are independent (no shared mutable state)
- [ ] No flaky tests (no sleep-based timing)
- [ ] Integration tests use real dependencies (not mocks for DB)

#### Test Completeness (if TEST-PLAN.md and TEST-REPORT.md exist)
- [ ] Every business rule in SPEC.md has at least one test case in TEST-PLAN.md
- [ ] All P0 test cases from TEST-PLAN.md are implemented (check TEST-REPORT.md)
- [ ] 95%+ of P1 test cases are implemented (check `test_case_coverage_minimum` gate)
- [ ] Test traceability comments present (`// Covers: TC-*`)
- [ ] No trivially passing tests (assertions are meaningful, not `expect(true).toBe(true)`)
- [ ] Contract tests exist for every API/event contract this service participates in
- [ ] Security test cases from TEST-PLAN.md section 4 have been executed
- [ ] Edge cases from the systematic checklist have been addressed (or documented as N/A with reason)

### Step 2: Cross-Service Review
- [ ] API contract consistency verified
- [ ] Event schemas are backwards-compatible
- [ ] Error propagation is consistent across service boundaries
- [ ] Correlation ID flows through the entire chain
- [ ] Logging format is consistent across services

### Step 3: Generate Review Report

Create `phases/7-review.md`:

```markdown
# Code Review Report

## Summary
- Services reviewed: [list]
- Critical issues: [N]
- Warnings: [N]
- Suggestions: [N]

## Critical Issues (Must Fix)
### [Issue Title]
- **Service**: [name]
- **File**: [path]
- **Issue**: [description]
- **Fix**: [what to do]

## Warnings (Should Fix)
...

## Suggestions (Nice to Have)
...

## Per-Service Scorecard

| Service | Security | Reliability | Performance | Maintainability | Testing | Test Completeness | Overall |
|---------|----------|-------------|-------------|-----------------|---------|-------------------|---------|
| [name]  | [A-F]    | [A-F]       | [A-F]       | [A-F]           | [A-F]   | [A-F]             | [A-F]   |

---
phase: review
status: complete
date: [today]
critical_issues: [N]
production_ready: [yes/no]
---
```

## Important Rules
- Be specific — "security issue" is not helpful; "missing input validation on POST /orders body.amount field" is
- Prioritize ruthlessly — critical issues are things that WILL cause production incidents
- Don't flag style preferences that aren't in the coding standards
- Suggest fixes, don't just identify problems
