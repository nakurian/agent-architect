# API Design Standards

> **Note**: For detailed backend implementation patterns (controller base classes, Swagger annotations, response flow), see [`backend-system-design-standard.md`](./backend-system-design-standard.md) sections 6, 11, and 24.

## REST Conventions

| Action | Method | Path | Response Code |
|--------|--------|------|---------------|
| List | GET | `/api/{resources}` | 200 |
| Get | GET | `/api/{resources}/{id}` | 200 |
| Create | POST | `/api/{resources}` | 201 |
| Update | PUT | `/api/{resources}/{id}` | 200 |
| Partial Update | PATCH | `/api/{resources}/{id}` | 200 |
| Delete | DELETE | `/api/{resources}/{id}` | 204 |
| Batch (read/write) | POST | `/api/{resources}/batch` | 200 |

### URL Conventions

```
Base:       /api
Management: /adm/actuator/*
Swagger:    /adm/swagger-ui.html, /adm/api-docs
```

## Response Envelope — `ApiResponse<T>`

All responses MUST use the shared library's `ApiResponse<T>` envelope.

### Success Response
```json
{
    "status": "OK",
    "message": "OK",
    "traceId": "6f2b8a1c4d...",
    "payload": { ... },
    "errors": null
}
```

### Paginated Response
```json
{
    "status": "OK",
    "message": "OK",
    "traceId": "6f2b8a1c4d...",
    "payload": {
        "data": [ ... ],
        "totalSize": 150,
        "totalPages": 15
    },
    "errors": null
}
```

Parameters: `?page=0&size=10` (zero-indexed, default 10)

### Error Response
```json
{
    "status": "BAD_REQUEST",
    "message": "Validation failed",
    "traceId": "6f2b8a1c4d...",
    "payload": null,
    "errors": [
        {
            "userMessage": "startDate is required and must be valid",
            "code": null,
            "title": null
        }
    ]
}
```

## HTTP Status Codes

| Code | When |
|------|------|
| 200 | Successful GET, successful batch operation |
| 201 | Resource created (POST that creates) |
| 204 | Successful DELETE (no body) |
| 304 | ETag match (not modified) |
| 400 | Validation failure, bad request format |
| 401 | Missing/invalid JWT token |
| 404 | Resource not found |
| 409 | Conflict (e.g., duplicate entry, capacity exceeded) |
| 412 | ETag mismatch (precondition failed) |
| 422 | Unprocessable entity (business rule violation) |
| 429 | Rate limited — include `Retry-After` header |
| 500 | Unexpected server error |
| 503 | Service unavailable (circuit breaker open) |

## Naming Conventions

- URLs: kebab-case (`/start-dates`, not `/startDates`)
- Query params: camelCase (`?locationCode=NYC&startDate=2026-06-15`)
- JSON fields: camelCase
- Event names: dot-notation lowercase (`order.updated`, `user.created`)

## Versioning

- Default base path: `/api` (no version segment)
- When breaking changes are required, introduce URL path versioning: `/api/v1/...`, `/api/v2/...`
- Support previous version for minimum 6 months after deprecation notice
- Most internal domain services operate without version segments since breaking changes are managed via deployment coordination

## Rate Limiting

- Return `429 Too Many Requests` with `Retry-After` header
- Default limits per tier:
  - Public: 100 req/min
  - Authenticated: 1000 req/min
  - Service-to-service: 10000 req/min

## Authentication

- Bearer token in `Authorization` header
- Controllers extend `SecureController` for authenticated endpoints
- JWT validation via shared library IAM module
- Service-to-service: mutual TLS or API keys in `X-Api-Key` header
- Role-based scopes per domain (e.g., `{domain}.read`, `{domain}.write`, `{domain}.admin`)

## Cross-Service Communication

- **Synchronous**: HTTP REST via `WebClient` (reactive, non-blocking)
- **Asynchronous**: Kafka events for eventual consistency and notifications
- Always propagate `traceId` for distributed tracing (automatic via Micrometer Brave)
- Use circuit breaker pattern (`@CircuitBreaker`) for external service calls
- Use retry with exponential backoff for transient failures

## Swagger Documentation

Every controller and endpoint MUST have OpenAPI annotations:
- `@Tag` on controller class
- `@Operation` + `@ApiResponses` on every endpoint method
- `@Parameter` on path/query parameters with descriptions and examples
