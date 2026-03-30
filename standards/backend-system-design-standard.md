# Backend System Design Standard

> **Version:** 1.0.0
> **Effective Date:** 2026-03-18
> **Audience:** All backend engineers
> **Stack:** Java 21 · Spring Boot 3.4+ · Spring WebFlux · Couchbase · Hazelcast · Kafka
> **Shared Library:** `com.example.platform:common-web` (`starter-common-web`)

---

## Table of Contents

1. [Guiding Principles](#1-guiding-principles)
2. [Project Structure & Module Layout](#2-project-structure--module-layout)
3. [Build & Dependency Management](#3-build--dependency-management)
4. [Application Configuration](#4-application-configuration)
5. [Layered Architecture](#5-layered-architecture)
6. [Controller Layer Standards](#6-controller-layer-standards)
7. [Service Layer Standards](#7-service-layer-standards)
8. [Data Access (DAO) Layer Standards](#8-data-access-dao-layer-standards)
9. [Domain Models & Persistence](#9-domain-models--persistence)
10. [DTO Design Standards](#10-dto-design-standards)
11. [Shared Library Usage (`starter-common-web`)](#11-shared-library-usage-starter-common-web)
12. [Reactive Programming Standards](#12-reactive-programming-standards)
13. [Java 21 & Functional Style Guidelines](#13-java-21--functional-style-guidelines)
14. [SOLID Principles — Applied](#14-solid-principles--applied)
15. [Cloud-Native Principles](#15-cloud-native-principles)
16. [Error Handling & Validation](#16-error-handling--validation)
17. [Caching Standards (Hazelcast)](#17-caching-standards-hazelcast)
18. [Database Standards (Couchbase)](#18-database-standards-couchbase)
19. [Messaging Standards (Kafka)](#19-messaging-standards-kafka)
20. [Observability Standards](#20-observability-standards)
21. [Security Standards](#21-security-standards)
22. [Testing Standards](#22-testing-standards)
23. [Code Quality Enforcement](#23-code-quality-enforcement)
24. [API Design Standards](#24-api-design-standards)
25. [Git & Versioning Standards](#25-git--versioning-standards)
26. [Appendix A: Naming Conventions](#appendix-a-naming-conventions)
27. [Appendix B: Recommended vs Discouraged Patterns](#appendix-b-recommended-vs-discouraged-patterns)
28. [Appendix C: Java 21 Feature Adoption Matrix](#appendix-c-java-21-feature-adoption-matrix)
29. [Appendix D: Checklist for New Service](#appendix-d-checklist-for-new-service)

<!-- AGENT SECTION INDEX — Use Read with offset/limit for targeted reading
     Regenerate line numbers after edits: grep -n '^## ' backend-system-design-standard.md
     §1  Guiding Principles ........... lines 78-110
     §2  Project Structure ............ lines 111-144
     §3  Build & Dependencies ......... lines 145-215
     §4  Application Config ........... lines 216-293
     §5  Layered Architecture ......... lines 294-340
     §6  Controller Layer ............. lines 341-426
     §7  Service Layer ................ lines 427-515
     §8  Data Access (DAO) ............ lines 516-665
     §9  Domain Models ................ lines 666-738
     §10 DTO Design ................... lines 739-833
     §11 Shared Library ............... lines 834-924
     §12 Reactive Programming ......... lines 925-1015
     §13 Java 21 & Functional ......... lines 1016-1240
     §14 SOLID Principles ............. lines 1241-1384
     §15 Cloud-Native ................. lines 1385-1487
     §16 Error Handling ............... lines 1488-1569
     §17 Caching (Hazelcast) .......... lines 1570-1657
     §18 Database (Couchbase) ......... lines 1658-1711
     §19 Messaging (Kafka) ............ lines 1712-1760
     §20 Observability ................ lines 1761-1850
     §21 Security ..................... lines 1851-1895
     §22 Testing ...................... lines 1896-2089
     §23 Code Quality ................. lines 2090-2138
     §24 API Design ................... lines 2139-2256
     §25 Git & Versioning ............. lines 2257-2308
     Appendix A: Naming ............... lines 2309-2350
     Appendix B: Patterns ............. lines 2351-2389
     Appendix C: Java 21 Matrix ....... lines 2390-2426
     Appendix D: New Service Checklist  lines 2427-2487
-->

---

## 1. Guiding Principles

### 1.1 Core Philosophy

| Principle | What It Means For Us |
|-----------|---------------------|
| **Reactive-First** | All I/O-bound operations use `Mono<T>` / `Flux<T>`. Never block the event loop. |
| **Functional over Imperative** | Prefer pure functions, immutable data, and declarative pipelines. Java 21 makes this idiomatic. |
| **SOLID by Default** | Every class has one reason to change. Depend on abstractions, not concretions. |
| **Cloud-Native by Design** | 12-factor apps, health probes, graceful shutdown, externalized config, distributed tracing. |
| **Offline-First** | Applications must function without guaranteed connectivity. Cache and local state are first-class citizens. |
| **Convention over Configuration** | Use the shared library (`starter-common-web`) to avoid reinventing cross-cutting concerns. |
| **Minimum Viable Complexity** | Write the simplest code that solves the problem. Three similar lines are better than a premature abstraction. |

### 1.2 Domain Language

Always use consistent domain terminology in code, comments, API paths, and documentation. Define a domain glossary for your project and enforce it across all services.

> **Legacy field names**: The shared library (`starter-common-web`) and existing Couchbase documents may use legacy field names that predate your current naming conventions. When working with shared library classes or existing persistence models, **use the established field names**. Apply updated domain terminology to **new** API paths, documentation, comments, and class names where no legacy convention exists.

---

## 2. Project Structure & Module Layout

### 2.1 Standard Package Layout

```
com.example.platform/
├── App.java                          # @SpringBootApplication entry point
├── annotations/                      # Custom annotations (@ValidDate, @AllowedValues, @TimedOperation)
│   └── impl/                         # Aspect implementations for custom annotations
├── config/                           # Spring @Configuration beans
├── controller/                       # REST controllers (extend BaseController)
├── dao/                              # Data Access Objects (Couchbase, Hazelcast)
│   └── transactional/                # Transaction runner abstractions
├── dto/                              # Request/response Data Transfer Objects
├── exception/                        # @ControllerAdvice, custom exception handlers
├── persistence/                      # Entity/model classes
│   └── model/                        # Domain models (User, Order, etc.)
├── serializers/                      # Hazelcast compact serializers
├── service/                          # Business logic interfaces
│   └── impl/                         # Service implementations
├── util/                             # Stateless utility classes
└── validators/                       # Domain-specific validators
```

### 2.2 Rules

- **One class per file.** No inner classes except for tightly-coupled nested types (e.g., `UserNotes.Note`).
- **Package-by-layer**, not package-by-feature, for consistency across all services.
- **Test mirrors source.** `src/test/java` mirrors the exact package path of `src/main/java`.
- **No circular dependencies** between packages. Dependencies flow: `controller → service → dao → persistence`.
- **Config classes** live in `config/` — never scatter `@Bean` definitions across service classes.

---

## 3. Build & Dependency Management

### 3.1 Build Tool

- **Gradle with Kotlin DSL** (`build.gradle.kts`) for application services.
- The shared library uses **Maven** (parent POM with multi-module). Downstream services consume it via Gradle.

### 3.2 Java Version

```kotlin
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}
```

> **Migration Note:** Current services target Java 17. New services MUST use Java 21. Existing services should migrate to Java 21 as part of their next major version.

### 3.3 Required Plugins

```kotlin
plugins {
    java
    checkstyle                                    // Google style, 0 max errors/warnings
    jacoco                                        // 80% minimum coverage
    id("org.springframework.boot") version "3.4.x"
    id("io.spring.dependency-management") version "1.1.x"
    id("com.diffplug.spotless") version "8.x"     // Code formatting
}
```

### 3.4 Shared Library Dependencies

Every service MUST depend on the appropriate `starter-common-web` modules:

```kotlin
dependencies {
    // Always required
    implementation("com.example.platform:core:${commonLibVersion}")

    // Per service need
    implementation("com.example.platform:couchbase:${commonLibVersion}")
    implementation("com.example.platform:hazelcast:${commonLibVersion}")
    implementation("com.example.platform:kafka:${commonLibVersion}")
    implementation("com.example.platform:iam:${commonLibVersion}")
    implementation("com.example.platform:util:${commonLibVersion}")
}
```

### 3.5 Dependency Hygiene

- **Exclude conflicting logging frameworks:** Logback excluded, use Log4j2.
- **Exclude Tomcat:** We use Netty (via WebFlux).
- **Force-override CVE-affected transitives:** Use `configurations.all { resolutionStrategy.force(...) }` and document the CVE number in a comment.
- **SNAPSHOT versions** only in development. Release builds pin exact versions.
- **Nexus credentials** via `gradle.properties` (local) or CI environment variables.

### 3.6 Git Hooks

Auto-install from `.githooks/` directory on build:

```kotlin
tasks.register<Exec>("installGitHooks") {
    commandLine("git", "config", "core.hooksPath", ".githooks")
}
tasks.named("build") { dependsOn("installGitHooks") }
```

---

## 4. Application Configuration

### 4.1 Configuration File

Use `application.yml` (not `.properties`). Use YAML anchors for shared values.

### 4.2 Structure

```yaml
spring:
  application:
    name: ${SERVICE_NAME}
  main:
    web-application-type: reactive          # Always reactive
  hazelcast:
    config: classpath:hazelcast.yml

server:
  port: ${SERVER_PORT:8087}
  shutdown: graceful                        # Always graceful
  netty:
    connection-timeout: 30s
    idle-timeout: 60s

management:
  endpoints:
    web:
      base-path: /adm/actuator
      exposure:
        include: health,info,loggers,metrics,prometheus
  endpoint:
    health:
      probes:
        enabled: true                       # Kubernetes liveness/readiness
  tracing:
    sampling:
      probability: 1.0                      # Full sampling in local environment

springdoc:
  swagger-ui:
    path: /adm/swagger-ui.html
  api-docs:
    path: /adm/api-docs

logging:
  level:
    root: INFO
    com.example.platform: INFO
  pattern:
    console: '%d{yyyy-MM-dd HH:mm:ss} [%X{traceId:-} %X{spanId:-}] - %msg%n'
```

### 4.3 Externalization Rules

| What | How |
|------|-----|
| Secrets (DB passwords, encryption keys) | Environment variables, never in YAML |
| Feature toggles | Environment variables with sensible defaults |
| Timeouts, TTLs, batch sizes | YAML with env-var override: `${ENV_VAR:default}` |
| Collection/bucket names | YAML with env-var override |
| CORS origins | YAML array with env-var override |

### 4.4 Custom Configuration Properties

Use type-safe `@ConfigurationProperties` with a prefix:

```java
@ConfigurationProperties(prefix = "batch.user")
public record BatchConfig(
    int maxSize,
    int kvConcurrency
) {}
```

> **Java 21 Recommendation:** Use `record` for configuration holders — immutable by default, constructor-validated.

---

## 5. Layered Architecture

```
┌─────────────────────────────────────────────────┐
│                   Client / BFF                  │
└───────────────────────┬─────────────────────────┘
                        │ HTTP (JSON)
┌───────────────────────▼─────────────────────────┐
│              Controller Layer                    │
│  • Extends BaseController / SecureController     │
│  • Input validation, Swagger docs                │
│  • Returns Mono<ResponseEntity<ApiResponse<T>>>  │
└───────────────────────┬─────────────────────────┘
                        │ Interface
┌───────────────────────▼─────────────────────────┐
│               Service Layer                      │
│  • Business logic, orchestration                │
│  • Transaction boundaries                       │
│  • Metrics recording                            │
│  • Cache coordination                           │
└───────────────────────┬─────────────────────────┘
                        │ Interface
┌───────────────────────▼─────────────────────────┐
│             DAO / Repository Layer               │
│  • Couchbase KV, N1QL, Analytics operations     │
│  • Hazelcast cache reads/writes                 │
│  • TTL management                               │
└───────────────────────┬─────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────┐
│           Persistence / Model Layer              │
│  • Extends CouchbaseEntity                      │
│  • Implements EntityMember (if applicable)     │
│  • Jackson serialization annotations            │
└─────────────────────────────────────────────────┘
```

### 5.1 Dependency Rules

- **Controller** depends on Service (interface), never on DAO.
- **Service** depends on DAO (concrete), Config, and other Services.
- **DAO** depends on Persistence models and Couchbase/Hazelcast SDK.
- **No layer** may depend on Controller.
- **Cross-cutting** (logging, metrics, security) via AOP aspects, never inline.

---

## 6. Controller Layer Standards

### 6.1 Base Class

All controllers MUST extend one of the shared library base controllers:

| Base Class | Use When |
|------------|----------|
| `BaseController` | Public endpoints (no auth required) |
| `SecureController` | Authenticated endpoints (JWT validation) |
| `SecureExternalController` | External-facing authenticated endpoints |

### 6.2 Class Annotations

```java
@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Domain Name", description = "Brief description of this controller's responsibility")
public class UserNotesController extends BaseController {
```

### 6.3 Method Patterns

```java
@GetMapping("/users/{customerId}/notes")
@Operation(summary = "Get all notes for a user")
@ApiResponses({
    @ApiResponse(responseCode = "200", content = @Content(schema = @Schema(implementation = ApiResponse.class))),
    @ApiResponse(responseCode = "404", description = "User not found"),
    @ApiResponse(responseCode = "400", description = "Invalid customer ID")
})
public Mono<ResponseEntity<ApiResponse<UserNotesResponse>>> getUserNotes(
        @PathVariable @NotBlank String customerId) {
    log.info("Fetching notes for customerId: {}", customerId);
    return getMonoResponse(userNotesService.getUserNotes(customerId));
}
```

### 6.4 Rules

| Rule | Rationale |
|------|-----------|
| **Always return `Mono<ResponseEntity<ApiResponse<T>>>`** | Consistent response envelope across all services |
| **Use `getMonoResponse()` / `getFluxResponse()`** from `BaseController` | Automatic error wrapping, traceId injection |
| **Validate at the boundary** | `@Valid`, `@NotBlank`, `@Pattern`, custom validators on parameters |
| **No business logic in controllers** | Controllers are thin — delegate to service layer immediately |
| **Log the entry point** | One `log.info()` at method start with key identifiers |
| **Use HTTP status codes correctly** | 200 OK, 201 CREATED, 204 NO_CONTENT, 400 BAD_REQUEST, 404 NOT_FOUND, 500 INTERNAL_SERVER_ERROR |
| **Document with Swagger** | `@Tag`, `@Operation`, `@ApiResponses`, `@Parameter` on every endpoint |
| **Batch endpoints use POST** | Even for read operations when the ID list is unbounded |

### 6.5 Pagination Pattern

```java
@GetMapping("/users")
public Mono<ResponseEntity<ApiResponse<PaginatedUserResponse>>> getUsers(
        @RequestParam @ValidDate String startDate,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size,
        @RequestParam(required = false) String search,
        @RequestParam(required = false) String unit) {
    return getMonoResponse(
        resourceService.getPaginatedUsersByStartDate(startDate, page, size, search, unit)
    );
}
```

### 6.6 Binary Response Pattern (Photos, Files)

```java
@GetMapping(value = "/user/{customerId}/photo", produces = MediaType.IMAGE_JPEG_VALUE)
public Mono<ResponseEntity<byte[]>> getUserPhoto(@PathVariable String customerId) {
    return resourceService.getUserPhotoByCustomerId(customerId)
        .map(photo -> ResponseEntity.ok()
            .contentType(MediaType.IMAGE_JPEG)
            .contentLength(photo.length)
            .cacheControl(CacheControl.maxAge(Duration.ofDays(7)).cachePublic().immutable())
            .body(photo))
        .defaultIfEmpty(ResponseEntity.notFound().build());
}
```

---

## 7. Service Layer Standards

### 7.1 Interface + Implementation Pattern

For services with multiple implementations or that need mockability in tests:

```java
// service/CacheManagerService.java
public interface CacheManagerService {
    boolean evictCache(String cacheName);
    Mono<CacheOperationResult> refreshUserCache(String startDate);
}

// service/impl/CacheManagerServiceImpl.java
@Service
@Slf4j
@RequiredArgsConstructor
public class CacheManagerServiceImpl implements CacheManagerService {
    private final UserDAO userDAO;
    private final MeterRegistry meterRegistry;
    // ...
}
```

For services with a single obvious implementation, a concrete `@Service` class is acceptable:

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class UserNotesService {
    private final UserNotesDAO userNotesDAO;
    private final BatchConfig batchConfig;
    // ...
}
```

### 7.2 Rules

| Rule | Rationale |
|------|-----------|
| **Constructor injection only** | Use `@RequiredArgsConstructor` with `final` fields. Never `@Autowired` on fields. |
| **Services are stateless** | No mutable instance state. All state lives in cache/database. |
| **Services own transactions** | Transaction boundaries start at the service layer, never in DAO. |
| **Services coordinate DAOs** | A service may compose multiple DAOs. A DAO never calls another DAO. |
| **Return reactive types** | `Mono<T>` or `Flux<T>` — never block. |
| **Record metrics here** | `Timer.Sample` for operation timing, counters for business events. |
| **Feature toggles checked here** | Use `@Value` to inject feature flags, check early, fail fast. |

### 7.3 Service Method Structure (Recommended)

```java
public Mono<UserNotesResponse> getUserNotes(String customerId) {
    return userNotesDAO.findByCustomerId(customerId)
        .map(UserNotesResponse::fromUserNotes)
        .defaultIfEmpty(UserNotesResponse.empty(customerId));
}
```

### 7.4 Transaction Pattern

```java
public Mono<Order> saveOrderData(CreateOrderRequestDTO requestDTO) {
    return transactionalRunner.run(ctx ->
        orderDAO.createOrUpdateTransactionalOrder(requestDTO, ctx)
            .flatMap(order ->
                orderPointerDAO.upsertTransactionalOrderPointer(order, ctx)
                    .thenReturn(order))
    );
}
```

### 7.5 Cache Coordination Pattern

```java
// 1. Execute business logic
// 2. Evict stale cache synchronously (fail-fast)
// 3. Reload cache asynchronously (fire-and-forget)
return transactionalRunner.run(ctx -> /* ... */)
    .doOnSuccess(order -> {
        cacheManagerService.evictCache(USER_CACHE);
        userDAO.getUsersByStartDateFromCluster(order.getStartDate())
            .subscribeOn(Schedulers.boundedElastic())
            .subscribe();
    });
```

---

## 8. Data Access (DAO) Layer Standards

### 8.1 Structure

DAOs handle all persistence concerns: Couchbase KV, N1QL queries, Analytics queries, and Hazelcast cache.

```java
@Service
@Slf4j
public class UserDAO extends HazelcastService<String, User> {
    private final ClusterServiceImpl clusterService;
    private final UnitCategoryService unitCategoryService;
    private final CouchbaseQueries couchbaseQueries;
    private final BatchConfig batchConfig;

    public UserDAO(ClusterServiceImpl clusterService, /* ... */) {
        this.clusterService = clusterService;
        // ...
    }
}
```

### 8.2 Data Access Patterns

#### KV Operations (Single Document)

```java
public Mono<User> findByCustomerIdFromCouchbase(String customerId) {
    return clusterService.getScope()
        .collection(userCollection).reactive()
        .get(customerId)
        .map(result -> result.contentAs(User.class))
        .onErrorResume(DocumentNotFoundException.class, e -> Mono.empty());
}
```

#### KV Partial Read (Sub-Document / LookupIn)

```java
public Mono<Boolean> checkPhotoExists(String customerId) {
    return collection.reactive()
        .lookupIn(customerId, List.of(LookupInSpec.exists("photoData")))
        .map(result -> result.exists(0))
        .onErrorReturn(false);
}
```

#### N1QL Query

```java
public Flux<User> getUsersByStartDateFromCluster(String startDate) {
    return clusterService.getCluster().reactive()
        .query(couchbaseQueries.getUserByStartDateQuery(),
               buildQueryOptions(Map.of("startDate", startDate), maxParallelism, timeout))
        .flatMapMany(result -> result.rowsAs(User.class));
}
```

#### Analytics Query

```java
public Flux<Staff> getStaffByDateFromCouchbase(String date) {
    return clusterService.getCluster().reactive()
        .analyticsQuery(couchbaseQueries.getStaffByDateQuery(),
                        buildAnalyticsOptions(Map.of("date", date), timeout))
        .flatMapMany(result -> result.rowsAs(Staff.class));
}
```

### 8.3 Cache-First Strategy

```
┌────────────┐     hit     ┌────────────┐
│   Request   │───────────▶│   Cache    │──▶ Return
└──────┬─────┘             └────────────┘
       │ miss                     ▲
       ▼                          │ populate
┌────────────┐             ┌──────┴─────┐
│  Couchbase  │───────────▶│   Cache    │
└────────────┘             └────────────┘
```

```java
public Mono<List<User>> getUsersByStartDate(String startDate) {
    List<User> cached = getFromCache(Predicates.equal("startDate", startDate));
    if (!cached.isEmpty()) {
        return Mono.just(cached);
    }
    return getUsersByStartDateFromCluster(startDate)
        .collectList()
        .doOnNext(users -> updateCacheSafely(() ->
            addAllToCache(users, User::getCustomerId)));
}
```

### 8.4 Batch KV Pattern

```java
public Flux<User> findByCustomerIds(List<String> customerIds) {
    // 1. Check cache first
    Map<String, User> cached = getFromCache(new HashSet<>(customerIds));
    Set<String> missing = customerIds.stream()
        .filter(id -> !cached.containsKey(id))
        .collect(Collectors.toSet());

    // 2. Fetch missing from DB with bounded concurrency
    Flux<User> fromDb = Flux.fromIterable(missing)
        .flatMap(this::findByCustomerIdFromCouchbase, batchConfig.getKvConcurrency())
        .onErrorResume(e -> {
            log.warn("Failed to fetch user: {}", e.getMessage());
            return Mono.empty();
        });

    // 3. Merge results
    return Flux.concat(Flux.fromIterable(cached.values()), fromDb);
}
```

### 8.5 TTL Calculation

```java
private Duration calculateTtl(User user) {
    if (StringUtils.isBlank(user.getExpirationDate())) {
        return Duration.ofDays(defaultRetentionDays);
    }
    try {
        var expiration = LocalDate.parse(user.getExpirationDate(), DATE_FORMATTER);
        var expiry = expiration.plusDays(userRetentionDays);
        var daysUntilExpiry = ChronoUnit.DAYS.between(LocalDate.now(), expiry);
        return Duration.ofDays(Math.max(daysUntilExpiry, 1));
    } catch (DateTimeParseException e) {
        log.warn("Invalid expiration date: {}", user.getExpirationDate());
        return Duration.ofDays(defaultRetentionDays);
    }
}
```

### 8.6 Rules

| Rule | Rationale |
|------|-----------|
| **DAOs extend `HazelcastService<K, V>`** when caching is needed | Provides cache primitives from shared library |
| **DAOs never call other DAOs** | Service layer orchestrates multi-DAO operations |
| **Handle `DocumentNotFoundException` gracefully** | Return `Mono.empty()`, never propagate raw Couchbase exceptions |
| **Log cache hits/misses at DEBUG** | Essential for performance troubleshooting |
| **Use parameterized queries** | Never concatenate user input into N1QL strings |
| **Configure timeouts per query** | Different operations have different SLAs |

---

## 9. Domain Models & Persistence

### 9.1 Base Entity

All domain models extend `CouchbaseEntity` from the shared library:

```java
public class CouchbaseEntity {
    private String id;
    private String crtBy;       // Created by
    private String crtDtm;      // Created datetime (epoch millis as string)
    private String uptBy;       // Updated by
    private String uptDtm;      // Updated datetime (epoch millis as string)
    private String version;
    private String docType;

    public void updateMetadata() { /* updates uptBy, uptDtm */ }
    public void setMetadata(String docType) { /* initializes all fields */ }
}
```

### 9.2 Model Structure

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@JsonIgnoreProperties(ignoreUnknown = true)
public class User extends CouchbaseEntity implements EntityMember {

    @JsonProperty("customerId")
    private String customerId;

    @JsonProperty("startDate")
    private String startDate;

    // ... domain fields ...

    @JsonIgnore
    private transient String scheduleWindowStart;  // Runtime-only, not persisted

    @Override
    public String type() { return "user"; }
}
```

### 9.3 Rules

| Rule | Rationale |
|------|-----------|
| **Always `@JsonIgnoreProperties(ignoreUnknown = true)`** | Tolerates schema evolution and external system changes |
| **Use `@JsonProperty` for external field mapping** | Decouple internal naming from external contracts |
| **Use `@JsonIgnore` for transient runtime fields** | Prevent accidental serialization of computed values |
| **Extend `CouchbaseEntity`** | Consistent metadata (audit fields, versioning) across all documents |
| **Implement `EntityMember`** if the entity appears in entity hierarchies | Enables polymorphic handling (user or staff) |
| **No business logic in models** | Models are data carriers. Logic lives in services. |
| **Nested entities as inner classes** when tightly coupled | e.g., `UserNotes.Note` — avoids top-level class proliferation |

### 9.4 Java 21 Enhancement — Sealed Interfaces for Domain Types

```java
public sealed interface EntityMember permits User, Staff {
    String getId();
    String type();
    byte[] getPhotoData();
    void setPhotoData(byte[] data);
}
```

---

## 10. DTO Design Standards

### 10.1 DTO Categories

| Category | Pattern | Example |
|----------|---------|---------|
| **Immutable value** | Java `record` | `CacheOperationResult` |
| **Request with validation** | Lombok `@Data` + `@Builder` + Jakarta validation | `AddNoteRequest` |
| **Response with mapping** | Lombok `@Data` + `@Builder` + static factory | `UserNotesResponse` |
| **External system mapping** | Lombok `@Data` + `@JsonProperty` mappings | `ExternalSystemDTO`, `AccountDetailDTO` |
| **Pagination wrapper** | Generic Lombok `@Data` | `PaginatedUserResponse` |
| **Polymorphic container** | Lombok `@Data` + multiple `@Valid` nested fields | `ExternalSystemRequest` |

### 10.2 Java 21 Recommendation — Prefer Records for Simple DTOs

```java
// Response DTO — immutable, concise, equals/hashCode/toString for free
public record CacheOperationResult(boolean success) {}

// Pagination response
public record PaginatedResponse<T>(List<T> data, int totalSize, int totalPages) {}

// Configuration holder
public record BatchConfig(int maxSize, int kvConcurrency) {}
```

> **When NOT to use records:** DTOs that need Jackson `@JsonProperty` remapping to external PascalCase fields, DTOs with builders for complex construction, or DTOs that implement `IEntityValidation`.

### 10.3 Factory Methods for Entity-to-DTO Conversion

```java
@Data
@Builder
public class NoteResponse {
    private String id;
    private String content;
    private String createdBy;
    private long createdAt;

    public static NoteResponse fromNote(UserNotes.Note note) {
        return NoteResponse.builder()
            .id(note.getId())
            .content(note.getContent())
            .createdBy(note.getCrtBy())
            .createdAt(Long.parseLong(note.getCrtDtm()))
            .build();
    }
}
```

### 10.4 Request Validation

```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddNoteRequest {
    @NotBlank(message = "Note content is mandatory")
    private String content;

    private String createdBy;
}
```

For complex cross-field validation, implement `IEntityValidation` from the shared library:

```java
public class ResourceRequest implements IEntityValidation {
    private String startDate;
    private String locationCode;

    @Override
    public List<IValidationError> validate() {
        var errors = new ArrayList<IValidationError>();
        validateIsNotBlank(errors, startDate, "startDate");
        validateIsNotBlank(errors, locationCode, "locationCode");
        return errors;
    }
}
```

### 10.5 Rules

| Rule | Rationale |
|------|-----------|
| **DTOs never contain business logic** | Pure data carriers |
| **One DTO per request/response shape** | No reusing a "God DTO" across unrelated endpoints |
| **Validate at the boundary** | Jakarta validation on request DTOs, `IEntityValidation` for cross-field logic |
| **Static factory methods** for entity → DTO | Keeps mapping co-located with the DTO definition |
| **`@NotBlank` over `@NotNull`** for strings | Catches both null and empty/whitespace strings |
| **`@NotEmpty` for collections** | Ensures at least one element in batch requests |

---

## 11. Shared Library Usage (`starter-common-web`)

### 11.1 Module Reference

| Module | Dependency | What You Get |
|--------|-----------|--------------|
| **core** | Always required | `BaseController`, `ApiResponse`, `ApiError`, `ResponseFactory`, `ValidationException`, `IEntityValidation`, ETag support, global exception handlers, execution time logging |
| **couchbase** | When using Couchbase | `ClusterServiceImpl` (connection management), config via env vars |
| **hazelcast** | When using distributed cache | `HazelcastService<K,V>` abstract class, `@HazelcastCache` annotation, TTL management |
| **iam** | When JWT auth is needed | `SecureController`, `ApiAuthorizationUtil`, `EncryptUtil`, JWK caching |
| **kafka** | When using Kafka messaging | `KafkaEventPublisher`, producer/consumer auto-config |
| **util** | Common utilities | `DateHelper`, `PaginationHelper`, `SearchHelper` (Jaro-Winkler fuzzy search) |

### 11.2 Response Flow

```
Your Controller Method
    │
    ├─ getMonoResponse(service.doSomething())
    │       │
    │       ├─ Success → ResponseFactory.createOKResponse(payload)
    │       │       → { status: "OK", message: "OK", traceId: "abc123", payload: {...} }
    │       │
    │       ├─ Empty → ResponseFactory.createNotFoundResponse(...)
    │       │       → { status: "NOT_FOUND", message: "...", traceId: "abc123" }
    │       │
    │       └─ Error → ResponseFactory.createCustomErrorResponse(throwable)
    │               → { status: "BAD_REQUEST", message: "...", traceId: "abc123", errors: [...] }
    │
    └─ ResponseEntity<ApiResponse<T>> (with HTTP status code)
```

### 11.3 Exception Hierarchy

```
RuntimeException
└── ValidationException
    ├── errorType: REGULAR     → 400 BAD_REQUEST (default)
    ├── errorType: NOT_FOUND   → 404 NOT_FOUND
    └── errorType: STALE_ETAG  → 412 PRECONDITION_FAILED
```

**Factory methods from `ExceptionUtils`:**

```java
ExceptionUtils.buildBadRequestException("Invalid start date format");
ExceptionUtils.buildNotFoundException("User not found: " + customerId);
ExceptionUtils.buildInternalServerErrorException("Database connection failed");
```

### 11.4 Validation Framework

The shared library provides a two-tier validation framework:

**Tier 1 — Jakarta Bean Validation** (annotation-based, handled by Spring):
- `@NotBlank`, `@NotNull`, `@NotEmpty`, `@Pattern`, `@Size`, `@Valid`
- Custom: `@ValidDate`, `@AllowedValues`
- Caught by `WebFluxExceptionsHandler` → 400

**Tier 2 — `IEntityValidation`** (programmatic, called by `BaseController`):
- Implement `validate()` returning `List<IValidationError>`
- Use built-in helpers: `validateIsNotBlank()`, `validateMustBeNumericIfNotBlank()`, etc.
- Called before business logic execution in `executeOperationValidated()`

### 11.5 ETag Support

For cacheable resources that need optimistic concurrency:

```java
public class OrderResponse implements IEtag {
    private Order order;
    private String etag;

    @Override
    public String getEtag() { return etag; }
}
```

Controller uses ETag-aware methods:

```java
return getOperationByStringParamWithMessageEtag(
    orderService::getOrder, orderId, "OrderId", eTag);
```

The framework automatically returns:
- `304 NOT_MODIFIED` if ETag matches
- `412 PRECONDITION_FAILED` if ETag is stale during updates

---

## 12. Reactive Programming Standards

### 12.1 Core Rules

| Rule | Example |
|------|---------|
| **Never call `.block()`** in production code | Only in tests or `@PostConstruct` initialization |
| **Never use `Thread.sleep()`** | Use `Mono.delay()` or `delayElement()` |
| **Chain operators, don't nest callbacks** | `flatMap` chain, not `subscribe` inside `subscribe` |
| **Use `switchIfEmpty` for empty fallback** | Not `defaultIfEmpty` when you need a reactive alternative |
| **Use `onErrorResume` for error recovery** | Not try-catch around reactive chains |
| **Use `doOnNext/doOnError/doFinally` for side effects** | Logging, metrics — not business logic |
| **Specify concurrency in `flatMap`** | `flatMap(fn, concurrency)` to prevent unbounded parallelism |
| **Use `Schedulers.boundedElastic()`** for blocking I/O | Image resizing, file operations |

### 12.2 Operator Decision Tree

```
Need to transform one value?
├── Synchronous → .map(fn)
└── Asynchronous → .flatMap(fn)

Need to handle empty?
├── Replace with default value → .defaultIfEmpty(value)
├── Replace with alternative Mono → .switchIfEmpty(Mono.defer(...))
└── Throw error → .switchIfEmpty(Mono.error(...))

Need error recovery?
├── Return fallback value → .onErrorReturn(value)
├── Return fallback Mono → .onErrorResume(fn)
└── Log and rethrow → .doOnError(e -> log.error(...))

Need side effects?
├── On each emission → .doOnNext(fn)
├── On success → .doOnSuccess(fn)
├── On error → .doOnError(fn)
├── On completion (any signal) → .doFinally(signal -> fn)
└── On subscribe → .doOnSubscribe(fn)

Need to collect?
├── Flux to List → .collectList()
├── Flux to Map → .collectMap(keyFn, valueFn)
└── Flux to sorted List → .collectSortedList(comparator)
```

### 12.3 Anti-Patterns

```java
// BAD: Blocking in reactive pipeline
return userDAO.findByCustomerId(id)
    .map(user -> {
        byte[] photo = photoService.getPhoto(user).block(); // NEVER
        user.setPhotoData(photo);
        return user;
    });

// GOOD: Reactive composition
return userDAO.findByCustomerId(id)
    .flatMap(user -> photoService.getPhoto(user)
        .map(photo -> { user.setPhotoData(photo); return user; }));
```

```java
// BAD: Nesting subscriptions
userDAO.findByCustomerId(id)
    .subscribe(user -> {
        notesDAO.findByCustomerId(user.getId())
            .subscribe(notes -> { /* callback hell */ });
    });

// GOOD: Flat chain
userDAO.findByCustomerId(id)
    .flatMap(user -> notesDAO.findByCustomerId(user.getId())
        .map(notes -> new UserWithNotes(user, notes)));
```

### 12.4 Testing Reactive Code

Always use `StepVerifier`:

```java
StepVerifier.create(service.getUserNotes("P001"))
    .assertNext(response -> {
        assertThat(response.getCustomerId()).isEqualTo("P001");
        assertThat(response.getNotes()).hasSize(2);
    })
    .verifyComplete();
```

---

## 13. Java 21 & Functional Style Guidelines

### 13.1 Feature Adoption Matrix

| Feature | Adopt? | Use Case |
|---------|--------|----------|
| **Records** | YES | DTOs, config holders, value objects, tuple-like returns |
| **Sealed classes/interfaces** | YES | Domain type hierarchies (EntityMember, error types) |
| **Pattern matching (`switch`)** | YES | Type dispatch, enum handling, optional unwrapping |
| **Pattern matching (`instanceof`)** | YES | Replace cast-after-instanceof |
| **Text blocks** | YES | N1QL queries, JSON templates, log messages |
| **`var` (local variable type inference)** | YES | When the type is obvious from the RHS |
| **Virtual threads** | CONDITIONAL | CPU-bound blocking tasks only — WebFlux already handles I/O concurrency via event loop |
| **Sequenced collections** | YES | When insertion order matters (`SequencedMap`, `SequencedSet`) |
| **String templates** | EXPERIMENTAL | Wait for stable release |
| **Scoped values** | EXPERIMENTAL | Wait for stable release |

### 13.2 Records

```java
// Configuration
public record PhotoConfig(int timeoutMillis, int fetchConcurrency) {}

// API response
public record PaginatedResponse<T>(List<T> data, int totalSize, int totalPages) {
    public PaginatedResponse {
        data = List.copyOf(data);  // Defensive copy in compact constructor
    }
}

// Internal value transfer
public record CacheResult<T>(T value, boolean fromCache) {}

// Multi-return
public record ValidationResult(boolean valid, List<String> errors) {
    public static ValidationResult success() { return new ValidationResult(true, List.of()); }
    public static ValidationResult failure(List<String> errors) { return new ValidationResult(false, errors); }
}
```

### 13.3 Sealed Types

```java
// Domain type hierarchy
public sealed interface EntityMember permits User, Staff {
    String getId();
    String type();
}

// Result type (like Rust's Result<T, E>)
public sealed interface ServiceResult<T> {
    record Success<T>(T value) implements ServiceResult<T> {}
    record NotFound<T>(String message) implements ServiceResult<T> {}
    record Error<T>(String message, Throwable cause) implements ServiceResult<T> {}
}
```

### 13.4 Pattern Matching

```java
// switch expression with pattern matching
return switch (member) {
    case User user -> processUser(user);
    case Staff staff   -> processStaff(staff);
};

// Pattern matching for instanceof (eliminate cast)
if (exception instanceof ValidationException rve) {
    return createErrorResponse(rve.getUserMsg(), rve.getHttpStatusCode());
}

// Guarded patterns
return switch (result) {
    case Success<User> s when s.value().isPremium() -> handlePremiumUser(s.value());
    case Success<User> s                          -> handleStandardUser(s.value());
    case NotFound<User> nf                        -> handleNotFound(nf.message());
    case Error<User> err                          -> handleError(err.cause());
};

// switch over strings/enums
String cacheAction = switch (cacheName) {
    case "user" -> userDAO.evictAll() ? "evicted" : "failed";
    case "staff"  -> staffDAO.evictAll() ? "evicted" : "failed";
    default      -> throw new IllegalArgumentException("Unknown cache: " + cacheName);
};
```

### 13.5 Functional Style Principles

#### Prefer Pure Functions

```java
// BAD: Side-effecting method
public void processUser(User user) {
    user.setUnitCategory(lookupCategory(user.getUnitId()));
    user.setIsPremium(checkPremium(user.getUnitCategory()));
    userDAO.save(user);
}

// GOOD: Pure transformation + explicit effect
public User enrichUser(User user) {
    var category = lookupCategory(user.getUnitId());
    return user.toBuilder()
        .unitCategory(category.name())
        .isPremium(category.isPremium())
        .build();
}
// Caller: userDAO.save(enrichUser(user))
```

#### Prefer Immutable Data

```java
// Use List.of(), Map.of(), Set.of() for immutable collections
var queryParams = Map.of("startDate", startDate, "locationCode", locationCode);

// Use List.copyOf() in record compact constructors
public record BatchRequest(List<String> customerIds) {
    public BatchRequest { customerIds = List.copyOf(customerIds); }
}

// Use Stream collectors that produce unmodifiable collections
var userIds = users.stream()
    .map(User::getCustomerId)
    .collect(Collectors.toUnmodifiableSet());
```

#### Use Stream Pipelines Idiomatically

```java
// Filtering, mapping, collecting
var premiumUsers = users.stream()
    .filter(User::isPremium)
    .sorted(Comparator.comparing(User::getLastName))
    .toList();  // Java 16+ — returns unmodifiable list

// Grouping
var usersByUnit = users.stream()
    .collect(Collectors.groupingBy(User::getUnitId));

// Partitioning
var partitioned = users.stream()
    .collect(Collectors.partitioningBy(User::isPremium));
// partitioned.get(true)  → premium users
// partitioned.get(false) → non-premium users

// Reducing
var totalUsers = startDates.stream()
    .mapToInt(date -> getUserCount(date))
    .sum();
```

#### Use Optional Correctly

```java
// GOOD: Optional as return type for "may not exist"
public Optional<UnitCategory> getUnitCategory(String code) {
    return Optional.ofNullable(unitCategories.get(code));
}

// GOOD: Chain operations
return getUnitCategory(code)
    .map(UnitCategory::name)
    .orElse("Unknown");

// BAD: Optional as method parameter
public void save(Optional<String> note) { /* Don't do this */ }

// BAD: Optional.get() without check
var name = getUnitCategory(code).get(); // Throws if empty

// GOOD: Use ifPresent, map, orElse, orElseThrow
getUnitCategory(code).ifPresent(cat -> log.info("Category: {}", cat.name()));
```

#### Compose Functions

```java
// Function composition for transformations
Function<User, User> enrichWithCategory = user -> {
    var cat = unitCategoryService.getUnitCategory(user.getUnitCategory());
    user.setUnitCategoryName(cat.map(UnitCategory::name).orElse("Unknown"));
    user.setIsPremium(cat.map(UnitCategory::isPremium).orElse(false));
    return user;
};

Function<User, User> enrichWithSchedule = user -> {
    scheduleWindow.ifPresent(mw -> {
        user.setScheduleWindowStart(mw.startTime());
        user.setScheduleWindowEnd(mw.endTime());
    });
    return user;
};

// Compose
var fullEnrichment = enrichWithCategory.andThen(enrichWithSchedule);
return users.stream().map(fullEnrichment).toList();
```

### 13.6 Text Blocks for Queries

```java
private static final String USER_QUERY = """
    SELECT META().id, g.*
    FROM `app`.`platform`.`user` g
    WHERE g.startDate = $startDate
    ORDER BY g.lastName ASC
    """;
```

### 13.7 `var` Usage Guidelines

```java
// YES: Type is obvious from RHS
var users = new ArrayList<User>();
var response = ResponseEntity.ok().body(payload);
var timer = Timer.start(meterRegistry);

// NO: Type is not obvious
var result = service.process(input);  // What type is result?
var x = getFromCache(key);            // What does getFromCache return?
```

---

## 14. SOLID Principles — Applied

### 14.1 Single Responsibility Principle (SRP)

> *A class should have one, and only one, reason to change.*

| Layer | Responsibility | NOT Its Responsibility |
|-------|---------------|----------------------|
| Controller | HTTP routing, input validation, Swagger docs | Business logic, data access |
| Service | Business logic, transaction coordination, metrics | HTTP concerns, SQL/N1QL queries |
| DAO | Data persistence, caching, TTL management | Business rules, HTTP status codes |
| DTO | Data shape for a specific API contract | Business logic, persistence |
| Model | Domain data representation | View formatting, validation messages |
| Config | Bean creation, property binding | Business logic |
| Aspect | Cross-cutting concern (logging, timing) | Business logic |

**Anti-pattern to avoid:**

```java
// BAD: Controller doing business logic
@GetMapping("/users")
public Mono<ResponseEntity<ApiResponse<List<User>>>> getUsers(@RequestParam String startDate) {
    // Controller should NOT be filtering, sorting, paginating
    return userDAO.getAll()
        .filter(g -> g.getStartDate().equals(startDate))
        .sort(Comparator.comparing(User::getLastName))
        .collectList()
        .map(/* ... */);
}

// GOOD: Delegate to service
@GetMapping("/users")
public Mono<ResponseEntity<ApiResponse<PaginatedUserResponse>>> getUsers(
        @RequestParam @ValidDate String startDate,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "10") int size) {
    return getMonoResponse(resourceService.getPaginatedUsersByStartDate(startDate, page, size));
}
```

### 14.2 Open/Closed Principle (OCP)

> *Open for extension, closed for modification.*

**Strategy: Use interfaces and sealed types instead of if/else chains.**

```java
// BAD: Modifying MessageController every time a new message type is added
if (request.getGenericAccountAddUpdate() != null) { /* user */ }
else if (request.getGenericStaffAddUpdate() != null) { /* staff */ }
else if (request.getGenericNewOrder() != null) { /* order */ }
// Adding a new type means modifying this method

// BETTER: Command pattern with sealed interface
public sealed interface InboundCommand permits
    UserUpsertCommand, StaffUpsertCommand, OrderCreateCommand, ScheduleUpdateCommand {
    Mono<Void> execute();
}
```

**Strategy: Use AOP for cross-cutting concerns.**

```java
// Instead of adding timing code to every method:
@TimedOperation(metricName = "user.save")
public Mono<User> saveUser(User user) { /* ... */ }

// The aspect handles the cross-cutting concern without modifying business code
```

### 14.3 Liskov Substitution Principle (LSP)

> *Subtypes must be substitutable for their base types.*

```java
// EntityMember interface — User and Staff are interchangeable where EntityMember is expected
public Mono<EntityMember> getEntityMemberById(String id) {
    return userDAO.findByCustomerId(id)
        .cast(EntityMember.class)
        .switchIfEmpty(staffDAO.findByStaffId(id).cast(EntityMember.class));
}
```

**Anti-pattern:**
```java
// BAD: Throwing UnsupportedOperationException in a subtype
public class ReadOnlyUserDAO extends UserDAO {
    @Override
    public Mono<User> saveUser(User user) {
        throw new UnsupportedOperationException(); // Violates LSP
    }
}
```

### 14.4 Interface Segregation Principle (ISP)

> *No client should be forced to depend on methods it does not use.*

```java
// GOOD: Separate focused interfaces
public interface CacheManagerService {
    boolean evictCache(String cacheName);
    Mono<CacheOperationResult> refreshUserCache(String startDate);
}

public interface ScheduleWindowService {
    Mono<OrderLocationCodePointer> saveScheduleWindow(ScheduleTimeDTO dto);
    Mono<ScheduleTimeDTO> getCurrentScheduleWindow();
}

// BAD: One mega-interface
public interface UserOperations {
    Mono<User> save(User user);
    Mono<User> findById(String id);
    boolean evictCache(String name);
    Mono<Void> sendKafkaEvent(User user);
    Mono<byte[]> getPhoto(String id);
    // Too many unrelated methods
}
```

### 14.5 Dependency Inversion Principle (DIP)

> *Depend on abstractions, not concretions.*

```java
// GOOD: Service depends on interface
@Service
public class ScheduleWindowServiceImpl implements ScheduleWindowService {
    private final TransactionalRunner transactionalRunner;  // Interface
    // ...
}

// GOOD: Constructor injection — caller decides the implementation
public ScheduleWindowServiceImpl(TransactionalRunner transactionalRunner) {
    this.transactionalRunner = transactionalRunner;
}

// In production: CouchbaseTransactionalRunner is injected
// In tests: A mock or test double is injected
```

---

## 15. Cloud-Native Principles

### 15.1 Twelve-Factor Compliance

| Factor | How We Comply |
|--------|--------------|
| **I. Codebase** | One repo per service, tracked in Git |
| **II. Dependencies** | Gradle/Maven declares all deps; no system-level assumptions |
| **III. Config** | Environment variables for all environment-specific values |
| **IV. Backing Services** | Couchbase, Hazelcast, Kafka treated as attached resources via connection strings |
| **V. Build, Release, Run** | CI/CD pipeline: build JAR → tag release → deploy to K8s |
| **VI. Processes** | Stateless processes; all state in Couchbase/Hazelcast |
| **VII. Port Binding** | Embedded Netty, self-contained, exports HTTP on configured port |
| **VIII. Concurrency** | Scale via K8s horizontal pod autoscaling |
| **IX. Disposability** | Graceful shutdown, fast startup (< 30s), no external state in process |
| **X. Dev/Prod Parity** | Docker Compose for local dev mirrors production topology |
| **XI. Logs** | Structured logging to stdout, collected by platform |
| **XII. Admin Processes** | One-off tasks via dedicated endpoints (e.g., cache refresh) |

### 15.2 Health Probes

Every service MUST expose Kubernetes health probes:

```yaml
management:
  endpoint:
    health:
      probes:
        enabled: true
        # /adm/actuator/health/liveness  — is the JVM alive?
        # /adm/actuator/health/readiness — can it serve traffic?
        # /adm/actuator/health/startup   — has it finished initializing?
```

Use the shared library's `ApplicationEventPublisher` to manage availability:

```java
// When initialization fails:
eventPublisher.publishAppStatusBroken(exception);
// Sets AvailabilityState to BROKEN + REFUSING_TRAFFIC

// When initialization succeeds:
eventPublisher.publishAppStatusUp();
// Sets AvailabilityState to CORRECT + ACCEPTING_TRAFFIC
```

### 15.3 Graceful Shutdown

```yaml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

On `SIGTERM`:
1. Stop accepting new requests
2. Complete in-flight requests (up to 30s)
3. Close database connections
4. Flush metrics
5. Exit

### 15.4 Resource Limits

Configure per service in K8s entity hierarchies. Application-level safeguards:

```yaml
server:
  netty:
    connection-timeout: 30s
    idle-timeout: 60s

spring:
  webflux:
    timeout: 60s
```

### 15.5 Circuit Breaker Pattern

For external service calls (messaging middleware, IAM, external APIs):

```java
@CircuitBreaker(name = "iamService", fallbackMethod = "fallbackGetKeys")
@Retry(name = "iamService")
public Mono<Map<String, String>> getJWKKeys() {
    return webClient.get()
        .uri(iamJwkUrl)
        .retrieve()
        .bodyToMono(new ParameterizedTypeReference<>() {});
}
```

### 15.6 Idempotency

All write operations MUST be idempotent. Couchbase `upsert` is naturally idempotent. For non-idempotent operations:
- Use document versioning / CAS (Compare-And-Swap)
- Include an idempotency key in the request
- Check-before-write pattern

---

## 16. Error Handling & Validation

### 16.1 Exception Hierarchy

```
RuntimeException
└── ValidationException (from shared library)
    ├── httpStatusCode: BAD_REQUEST (400)
    ├── httpStatusCode: NOT_FOUND (404)
    ├── httpStatusCode: INTERNAL_SERVER_ERROR (500)
    └── errorType: REGULAR | NOT_FOUND | STALE_ETAG
```

### 16.2 Error Creation

```java
// 400 — bad input
throw ExceptionUtils.buildBadRequestException("Start date format must be yyyyMMdd");

// 404 — resource not found
throw ExceptionUtils.buildNotFoundException("User not found: " + customerId);

// 500 — internal failure
throw ExceptionUtils.buildInternalServerErrorException("Failed to save order data");
```

### 16.3 Reactive Error Handling

```java
// Pattern 1: switchIfEmpty for "not found"
return userDAO.findByCustomerId(id)
    .switchIfEmpty(Mono.error(buildNotFoundException("User not found: " + id)));

// Pattern 2: onErrorResume for fallback
return userDAO.findByCustomerId(id)
    .onErrorResume(DocumentNotFoundException.class, e -> Mono.empty());

// Pattern 3: onErrorResume with type-specific recovery
return photoService.fetchPhoto(id)
    .timeout(Duration.ofMillis(photoTimeout))
    .onErrorResume(TimeoutException.class, e -> {
        log.warn("Photo fetch timed out for: {}", id);
        return Mono.empty();
    });

// Pattern 4: doOnError for logging (without recovery)
return userDAO.saveUser(user)
    .doOnError(e -> log.error("Failed to save user: {}", user.getCustomerId(), e));
```

### 16.4 Global Exception Handling

The shared library provides `@ControllerAdvice` handlers for both WebFlux and MVC:
- `WebFluxExceptionsHandler` — handles `HandlerMethodValidationException`, `WebExchangeBindException`, `ServerWebInputException`
- All exceptions are wrapped in `ApiResponse` with `traceId`
- Custom handlers in your service should be additive (handle service-specific exceptions)

```java
@ControllerAdvice
public class ValidationHandler {
    @ExceptionHandler(HandlerMethodValidationException.class)
    public ResponseEntity<ApiResponse<String>> handleValidation(HandlerMethodValidationException ex) {
        var errors = extractValidationErrors(ex);
        return ResponseEntity.badRequest()
            .body(responseFactory.createBadRequestResponse("Validation failed", errors));
    }
}
```

### 16.5 Rules

| Rule | Rationale |
|------|-----------|
| **Never swallow exceptions silently** | Always log at minimum `warn` level |
| **Never expose stack traces to clients** | Use `userMsg` for client, `internalMessage` for logs |
| **Include `traceId` in all error responses** | `ResponseFactory` does this automatically |
| **Use typed exceptions, not generic `RuntimeException`** | `ValidationException` with appropriate `httpStatusCode` |
| **Fail fast on invalid input** | Validate at controller boundary, not deep in the service |
| **Prefer `Mono.error()` over `throw`** in reactive chains | Throwing breaks the reactive pipeline |

---

## 17. Caching Standards (Hazelcast)

### 17.1 Architecture

- **Embedded or client mode** (configured per environment)
- **Kubernetes service discovery** for cluster formation
- **Compact serialization** for efficient network transfer

### 17.2 Cache Map Configuration

```yaml
# hazelcast.yml
hazelcast:
  cluster-name: ${SERVICE_NAME}
  network:
    join:
      kubernetes:
        enabled: true
        service-name: ${SERVICE_NAME}
  serialization:
    compact-serialization:
      serializers:
        - serializer: com.example.platform.serializers.UserSerializer
  map:
    user:
      indexes:
        - name: startDateIndex
          type: SORTED
          attributes: [startDate]
        - name: customerIdIndex
          type: HASH
          attributes: [customerId]
```

### 17.3 DAO Integration

```java
@Service
@HazelcastCache(name = "user", expiryFromProps = "caches.user.ttl")
public class UserDAO extends HazelcastService<String, User> {
    // Inherits: getFromCache, addToCache, addAllToCache, evictAll, evictByKey
}
```

### 17.4 Custom Serializers

Every cached entity MUST have a compact serializer:

```java
public class UserSerializer implements CompactSerializer<User> {
    @Override
    public User read(CompactReader reader) {
        var user = new User();
        user.setCustomerId(reader.readString("customerId"));
        user.setStartDate(reader.readString("startDate"));
        // ... all fields
        SerializerUtils.setCouchbaseFields(reader, user);
        return user;
    }

    @Override
    public void write(CompactWriter writer, User user) {
        writer.writeString("customerId", user.getCustomerId());
        writer.writeString("startDate", user.getStartDate());
        // ... all fields
        SerializerUtils.writeCouchBaseFields(writer, user);
    }

    @Override
    public String getTypeName() { return "user"; }

    @Override
    public Class<User> getCompactClass() { return User.class; }
}
```

### 17.5 Rules

| Rule | Rationale |
|------|-----------|
| **Index frequently queried fields** | SORTED for range queries, HASH for equality |
| **Update serializer when model changes** | Missing fields cause deserialization failures |
| **Use `updateCacheSafely()`** for cache population | Errors in cache writes should not fail the request |
| **Eviction policy: NONE** for bounded datasets (users per period) | Data is naturally bounded by order lifecycle |
| **TTL from properties** | Different environments may need different TTLs |

---

## 18. Database Standards (Couchbase)

### 18.1 Document Design

- **Bucket:** `app` (shared application bucket)
- **Scope:** `platform` (per domain)
- **Collections:** One per entity type (`user`, `staff`, `order`, `time`)

### 18.2 Document Key Patterns

| Entity | Key Pattern | Example |
|--------|------------|---------|
| User | `{customerId}` | `12345` |
| Staff | `{staffId}` | `S001` |
| Order | `{orderId}` | `ORD2026001` |
| OrderPointer | `ORDER_POINTER_{locationCode}` | `ORDER_POINTER_NYC` |
| UserNotes | `{customerId}::notes` | `12345::notes` |

### 18.3 Query Options

```java
QueryOptions.queryOptions()
    .parameters(JsonObject.from(params))
    .maxParallelism(maxParallelism)
    .timeout(Duration.ofSeconds(timeoutSeconds))
    .readonly(true)  // For read queries — enables query plan caching
```

### 18.4 Transaction Pattern

```java
public <T> Mono<T> run(Function<ReactiveTransactionAttemptContext, Mono<T>> logic) {
    var ref = new AtomicReference<T>();
    return cluster.reactive().transactions()
        .run(ctx -> logic.apply(ctx).doOnNext(ref::set).then(),
             TransactionOptions.transactionOptions().durabilityLevel(durability))
        .then(Mono.defer(() -> Mono.justOrEmpty(ref.get())));
}
```

### 18.5 Rules

| Rule | Rationale |
|------|-----------|
| **KV operations for single-document CRUD** | Sub-millisecond latency |
| **N1QL for multi-document queries** | SQL-like flexibility with parameterized queries |
| **Analytics for heavy/offline reads** | Staff queries use analytics (separate workload isolation) |
| **LookupIn for partial reads** | Check field existence without fetching full document |
| **Always set TTL on documents** | Prevent unbounded storage growth |
| **Durability level from config** | NONE for dev, MAJORITY for production |
| **Parameterize all queries** | Prevent N1QL injection |

---

## 19. Messaging Standards (Kafka)

### 19.1 Configuration

```java
// Auto-configured via starter-common-web kafka module
// Environment variables:
// MSG_MW_ENABLED=true
// MSG_MW_ADDRESS=kafka-broker:9092
// MSG_MW_CHANNEL_NAME=user-events
// MSG_MW_CONCURRENCY=3
```

### 19.2 Publishing

```java
@Service
@RequiredArgsConstructor
public class UserEventPublisher {
    private final KafkaEventPublisher kafkaEventPublisher;

    public void publishUserUpdated(User user) {
        kafkaEventPublisher.publish(objectMapper.writeValueAsString(
            new UserUpdatedEvent(user.getCustomerId(), user.getStartDate())
        ));
    }
}
```

### 19.3 Consuming

```java
@KafkaListener(topics = "${MSG_MW_CHANNEL_NAME}", groupId = "${spring.application.name}")
public void handleEvent(String message) {
    // Process message
}
```

### 19.4 Rules

| Rule | Rationale |
|------|-----------|
| **Events are JSON strings** | Interoperable, schema-evolvable |
| **Use `IS_MSG_MW_ENABLED` toggle** | Disable messaging in environments without Kafka |
| **Consumer group = service name** | Ensures each service instance gets its share of partitions |
| **Idempotent consumers** | Messages may be delivered more than once |

---

## 20. Observability Standards

### 20.1 Structured Logging

```java
// Use SLF4J via Lombok @Slf4j
@Slf4j
public class ResourceService {

    public Mono<PaginatedUserResponse> getPaginatedUsers(String startDate, int page, int size) {
        log.info("Fetching paginated users: startDate={}, page={}, size={}", startDate, page, size);
        // ...
        log.debug("[{}ms] Loaded {} users from cache", elapsed, count);
    }
}
```

### 20.2 Logging Level Guidelines

| Level | When |
|-------|------|
| **ERROR** | Operation failed, manual intervention may be needed |
| **WARN** | Unexpected but recoverable (timeout, fallback used, parse failure) |
| **INFO** | Business-significant events (request received, cache evicted, order saved) |
| **DEBUG** | Developer troubleshooting (cache hit/miss, timing, query params) |
| **TRACE** | Execution time logging (via `@ExecutionTimeLogger` from shared library) |

### 20.3 Timing Pattern

```java
long startTime = System.currentTimeMillis();
// ... operation ...
long elapsed = System.currentTimeMillis() - startTime;
log.info("[{}ms] Operation completed for startDate: {}", elapsed, startDate);
```

### 20.4 Metrics (Micrometer)

```java
// Timer for operation duration
Timer.Sample sample = Timer.start(meterRegistry);
return userDAO.saveUser(user)
    .doOnSuccess(g -> sample.stop(meterRegistry.timer(
        "user.database.save",
        "startDate", user.getStartDate(),
        "success", "true")))
    .doOnError(e -> sample.stop(meterRegistry.timer(
        "user.database.save",
        "startDate", user.getStartDate(),
        "success", "false")));
```

```java
// Counter for events
meterRegistry.counter("user.cache.eviction.total", "success", String.valueOf(result)).increment();
```

```java
// Custom annotation for automatic timing
@TimedOperation(metricName = "schedule.window.save", tags = {"orderId"})
public Mono<OrderLocationCodePointer> saveScheduleWindow(ScheduleTimeDTO dto) { /* ... */ }
```

### 20.5 Distributed Tracing

- Micrometer Brave auto-configured via Spring Boot Actuator
- `traceId` and `spanId` included in log pattern: `[%X{traceId:-} %X{spanId:-}]`
- `traceId` included in every `ApiResponse` via `ResponseFactory`
- Reactor context propagation enabled: `Hooks.enableAutomaticContextPropagation()`

### 20.6 Required Actuator Endpoints

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,loggers,metrics,prometheus
```

| Endpoint | Purpose |
|----------|---------|
| `/adm/actuator/health` | K8s probes (liveness, readiness, startup) |
| `/adm/actuator/info` | Build info, git info |
| `/adm/actuator/loggers` | Runtime log level adjustment |
| `/adm/actuator/metrics` | Application metrics |
| `/adm/actuator/prometheus` | Prometheus scrape endpoint |

---

## 21. Security Standards

### 21.1 Authentication

Use `SecureController` from the IAM module for authenticated endpoints:

```java
@RestController
@RequestMapping("/api/secure")
public class SecureUserController extends SecureController {

    @GetMapping("/users")
    public ResponseEntity<ApiResponse<List<User>>> getUsers(
            @RequestHeader("Authorization") String token,
            @RequestParam String startDate) {
        return getOperationByStringParamWithMessage(
            token, List.of("user.read"),  // required scopes
            userService::getUsersByStartDate, startDate, "startDate");
    }
}
```

### 21.2 JWT Validation Flow

```
Request → Extract Bearer token → Decode JWT header → Get KID →
Fetch public key from cache → Verify RS256/RS512 signature →
Check scope/roles claim against required scopes →
Allow or return 401
```

### 21.3 Rules

| Rule | Rationale |
|------|-----------|
| **Never log tokens or secrets** | Use masked representations if needed |
| **Encryption keys from environment variables** | `ENCRYPTION_SECRET_KEY`, `ENCRYPTION_IV_PARAM` |
| **CORS configured per environment** | Restricted origins for production |
| **CSRF disabled for stateless REST APIs** | Document with `// deepcode ignore` comment |
| **Parameterize all queries** | Prevent injection attacks |
| **Validate all input at the boundary** | Never trust client data |
| **Use `EncryptUtil` (AES-GCM)** for sensitive data at rest | From shared library IAM module |

---

## 22. Testing Standards

### 22.1 Testing Pyramid

```
        ╱╲
       ╱  ╲       Integration Tests (WebFluxTest + MockMvc)
      ╱    ╲      10% — Controller + validation + response shape
     ╱──────╲
    ╱        ╲     Service Tests (Mockito + StepVerifier)
   ╱          ╲    30% — Business logic, reactive chains, error handling
  ╱────────────╲
 ╱              ╲   Unit Tests (JUnit 5 + Mockito)
╱                ╲  60% — DAO, utilities, serializers, validators
╱──────────────────╲
```

### 22.2 Framework Stack

| Tool | Purpose |
|------|---------|
| JUnit 5 | Test runner, `@Nested`, `@DisplayName`, `@ParameterizedTest` |
| Mockito | Mocking: `@Mock`, `@InjectMocks`, `when/thenReturn`, `verify` |
| StepVerifier | Reactive assertions for `Mono`/`Flux` |
| WebTestClient | Integration testing for WebFlux controllers |
| AssertJ | Fluent assertions (`assertThat(x).isEqualTo(y)`) |

### 22.3 Test Naming Convention

```
{methodName}_{condition}_{expectedResult}
```

Examples:
```java
@Test void saveUser_success() { }
@Test void findByCustomerId_notInCache_fetchesFromDatabase() { }
@Test void getPaginatedUsers_withSearchFilter_returnsFilteredResults() { }
@Test void addNote_blankContent_throwsBadRequest() { }
```

### 22.4 Controller Test Pattern

```java
@WebFluxTest(UserNotesController.class)
@Import(TestConfig.class)
class UserNotesControllerTest {

    @Autowired private WebTestClient webTestClient;
    @MockBean private UserNotesService userNotesService;

    @Test
    void getUserNotes_success() {
        var response = UserNotesResponse.builder()
            .customerId("P001")
            .notes(List.of(/* ... */))
            .build();

        when(userNotesService.getUserNotes("P001")).thenReturn(Mono.just(response));

        webTestClient.get()
            .uri("/api/users/P001/notes")
            .exchange()
            .expectStatus().isOk()
            .expectBody(new ParameterizedTypeReference<ApiResponse<UserNotesResponse>>() {})
            .consumeWith(result -> {
                var body = result.getResponseBody();
                assertThat(body.getPayload().getCustomerId()).isEqualTo("P001");
            });
    }
}
```

### 22.5 Service Test Pattern

```java
@ExtendWith(MockitoExtension.class)
class UserNotesServiceTest {

    @Mock private UserNotesDAO userNotesDAO;
    @Mock private BatchConfig batchConfig;
    @InjectMocks private UserNotesService userNotesService;

    @Test
    void addNote_success() {
        var request = AddNoteRequest.builder().content("VIP user").build();
        var notes = new UserNotes();
        notes.setCustomerId("P001");

        when(userNotesDAO.findByCustomerId("P001")).thenReturn(Mono.just(notes));
        when(userNotesDAO.save(any())).thenReturn(Mono.just(notes));

        StepVerifier.create(userNotesService.addNote("P001", request))
            .assertNext(response -> {
                assertThat(response.getCustomerId()).isEqualTo("P001");
            })
            .verifyComplete();
    }

    @Test
    void addNote_userNotFound_createsNewDocument() {
        when(userNotesDAO.findByCustomerId("P001")).thenReturn(Mono.empty());
        when(userNotesDAO.save(any())).thenReturn(Mono.just(new UserNotes()));

        StepVerifier.create(userNotesService.addNote("P001", request))
            .expectNextCount(1)
            .verifyComplete();

        verify(userNotesDAO).save(argThat(notes ->
            notes.getCustomerId().equals("P001")));
    }
}
```

### 22.6 DAO Test Pattern

```java
@ExtendWith(MockitoExtension.class)
class UserDAOTest {

    @Mock private ClusterServiceImpl clusterService;
    @Mock private ReactiveCollection reactiveCollection;
    @Mock private IMap<Object, Object> userCache;
    @InjectMocks private UserDAO userDAO;

    @Test
    void findByCustomerIdFromCouchbase_documentNotFound_returnsEmpty() {
        when(reactiveCollection.get("P001"))
            .thenReturn(Mono.error(new DocumentNotFoundException(null)));

        StepVerifier.create(userDAO.findByCustomerIdFromCouchbase("P001"))
            .verifyComplete();  // Empty Mono
    }
}
```

### 22.7 Test Utilities

Create a shared `TestUtils` class per service:

```java
public final class TestUtils {

    private TestUtils() {}

    public static User buildUser(String customerId) {
        return User.builder()
            .customerId(customerId)
            .startDate("20260318")
            .firstName("Test")
            .lastName("User")
            .build();
    }

    public static MeterRegistry createMockedMeterRegistry() {
        var registry = mock(MeterRegistry.class);
        // ... configure mock chain
        return registry;
    }

    public static byte[] createTestImage(int width, int height) {
        var image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        var baos = new ByteArrayOutputStream();
        ImageIO.write(image, "jpg", baos);
        return baos.toByteArray();
    }
}
```

### 22.8 Coverage Requirements

- **Minimum 80%** instruction coverage (JaCoCo)
- **Minimum 80%** branch coverage (JaCoCo)
- **Excluded from coverage:** annotations, config, DTOs, exceptions, persistence models, serializers, App.class

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

---

## 23. Code Quality Enforcement

### 23.1 Spotless (Formatting)

```kotlin
spotless {
    java {
        eclipse().configFile("config/eclipse-java-formatter.xml")
        // Google Java style variant, 120 char line limit
    }
}
```

Run: `./gradlew spotlessApply`

### 23.2 Checkstyle (Linting)

- **Style:** Google Java Style (modified)
- **Scope:** Main source only (not tests)
- **Tolerance:** 0 max errors, 0 max warnings

```kotlin
checkstyle {
    toolVersion = "10.25.0"
    maxErrors = 0
    maxWarnings = 0
    sourceSets = listOf(project.sourceSets["main"])
}
```

Run: `./gradlew checkstyleMain`

### 23.3 Pre-Commit Hooks

`.githooks/pre-commit` runs:
1. `spotlessCheck` — formatting
2. `checkstyleMain` — style
3. `test` — all tests pass

### 23.4 CI Pipeline Quality Gates

1. **Snyk** — dependency vulnerability scanning
2. **SonarQube** — code quality, code smells, duplication
3. **JaCoCo** — coverage verification (80% minimum)
4. **Checkstyle** — zero violations
5. **Spotless** — consistent formatting

---

## 24. API Design Standards

### 24.1 URL Conventions

```
Base: /api                        # default — no version segment
Versioned: /api/v1, /api/v2      # only when breaking changes require it
Management: /adm/actuator/*
Swagger: /adm/swagger-ui.html, /adm/api-docs
```

> **Versioning policy**: Most internal domain services use `/api` without a version segment. Introduce `/api/v1/`, `/api/v2/` only when a breaking change requires supporting multiple versions simultaneously. See `api-design.md` for full versioning policy.

| Pattern | Example | Method |
|---------|---------|--------|
| Collection | `/api/users` | GET (list), POST (create) |
| Single resource | `/api/users/{id}` | GET |
| Sub-resource | `/api/users/{id}/notes` | GET, POST |
| Sub-resource item | `/api/users/{id}/notes/{noteId}` | PUT, DELETE |
| Batch operation | `/api/users/batch` | POST (even for reads) |
| Binary resource | `/api/users/{id}/photo` | GET (produces image/jpeg) |
| Cache management | `/api/cache/{cacheName}` | GET (evict/refresh) |

> **Convention**: Always use **plural** resource names in URL paths (`/api/users`, not `/api/user`). This applies consistently to collection endpoints, single-resource lookups, and sub-resources.

### 24.2 Response Envelope

All responses MUST use `ApiResponse<T>`:

```json
{
    "status": "OK",
    "message": "OK",
    "traceId": "6f2b8a1c4d...",
    "payload": { ... },
    "errors": null
}
```

Error response:
```json
{
    "status": "BAD_REQUEST",
    "message": "Validation failed",
    "traceId": "6f2b8a1c4d...",
    "payload": null,
    "errors": [
        {
            "userMessage": "startDate is Required and must be valid",
            "code": null,
            "title": null
        }
    ]
}
```

### 24.3 Pagination Response

```json
{
    "status": "OK",
    "payload": {
        "data": [ ... ],
        "totalSize": 150,
        "totalPages": 15
    }
}
```

Parameters: `?page=0&size=10` (zero-indexed, default 10)

### 24.4 HTTP Status Code Usage

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

### 24.5 Swagger Documentation

Every controller and endpoint MUST have Swagger annotations:

```java
@Tag(name = "User Notes", description = "CRUD operations for user notes")
@RestController
@RequestMapping("/api/users")
public class UserNotesController extends BaseController {

    @Operation(summary = "Get all notes for a user",
               description = "Returns all notes associated with the given customer ID")
    @ApiResponses({
        @ApiResponse(responseCode = "200",
            content = @Content(schema = @Schema(implementation = ApiResponse.class))),
        @ApiResponse(responseCode = "404", description = "User not found"),
        @ApiResponse(responseCode = "400", description = "Invalid customer ID")
    })
    @GetMapping("/{customerId}/notes")
    public Mono<ResponseEntity<ApiResponse<UserNotesResponse>>> getUserNotes(
        @Parameter(description = "Unique customer identifier", required = true, example = "12345")
        @PathVariable @NotBlank String customerId) {
        // ...
    }
}
```

---

## 25. Git & Versioning Standards

### 25.1 Branching Strategy

```
main / develop
├── feature/{PROJECT}-{ticket}     # New features
├── fix/{description}        # Bug fixes
├── hotfix/{description}     # Production hotfixes
└── chore/{description}      # Maintenance tasks
```

### 25.2 Commit Convention

**Conventional Commits** format:

```
<type>[optional scope]: <description>

[optional body]
```

Types:
| Type | Semver Impact | Example |
|------|--------------|---------|
| `feat` | minor | `feat: add schedule endpoint` |
| `fix` | patch | `fix: upgrade jackson-core to 2.18.6 for CVE patch` |
| `feat!` | major | `feat!: change user response format` |
| `chore` | none | `chore: update dependencies` |
| `docs` | none | `docs: update API documentation` |
| `test` | none | `test: add UserNotesService unit tests` |
| `refactor` | none | `refactor: extract photo enrichment logic` |

### 25.3 Semantic Versioning

```
MAJOR.MINOR.PATCH
  │     │     └── fix: backward-compatible bug fixes
  │     └──────── feat: backward-compatible features
  └────────────── feat!: breaking changes
```

### 25.4 Version Management

```kotlin
val version: String = findProperty("version") as? String
    ?: System.getenv("VERSION")
    ?: "0.0.1-SNAPSHOT"
```

---

## Appendix A: Naming Conventions

### A.1 Code Naming

| Element | Convention | Example |
|---------|-----------|---------|
| Package | lowercase, dot-separated | `com.example.platform.service` |
| Class | PascalCase | `UserNotesService`, `ResourceController` |
| Interface | PascalCase (no `I` prefix for domain) | `CacheManagerService`, `EntityMember` |
| Interface (shared lib) | `I` prefix for framework contracts | `IEntityValidation`, `IEtag` |
| Method | camelCase, verb-first | `getUsersByStartDate`, `addNote`, `evictCache` |
| Variable | camelCase | `startDate`, `customerId`, `userCache` |
| Constant | UPPER_SNAKE_CASE | `API_NAME`, `USER_CACHE`, `DEFAULT_TTL` |
| DTO | PascalCase + suffix | `AddNoteRequest`, `UserNotesResponse`, `ExternalSystemDTO` |
| Config class | PascalCase + `Config` | `BatchConfig`, `CorsConfig`, `CouchbaseQueries` |
| Test class | Same as source + `Test` | `UserNotesServiceTest`, `ResourceControllerTest` |
| Test method | `methodName_condition_expectedResult` | `saveUser_success`, `findById_notFound_returnsEmpty` |

### A.2 Domain Field Names

| Field | Convention | Notes |
|-------|-----------|-------|
| User identifier | `customerId` | Consistent ID naming convention |
| Staff identifier | `staffId` | Consistent ID naming convention |
| Account | `accountId` | Standard ID |
| Room/Unit | `unitId` | Standard ID |
| Order | `orderId` or `startDate` | Use startDate for date-based lookups |
| Created metadata | `crtBy`, `crtDtm` | Short form from CouchbaseEntity |
| Updated metadata | `uptBy`, `uptDtm` | Short form from CouchbaseEntity |

### A.3 Metric Names

```
{domain}.{resource}.{operation}
```

Examples: `user.database.save`, `users.paginated.fetch`, `external.order.data.save`

Tags: key-value pairs for dimensions (`startDate`, `success`, `source`, `page`, `size`)

---

## Appendix B: Recommended vs Discouraged Patterns

### Recommended

| Pattern | Example |
|---------|---------|
| Constructor injection with `@RequiredArgsConstructor` | `private final UserDAO userDAO;` |
| Records for immutable DTOs | `record CacheResult(boolean success) {}` |
| Sealed interfaces for type hierarchies | `sealed interface EntityMember permits User, Staff` |
| Pattern matching in switch | `case User g -> processUser(g);` |
| Text blocks for queries | `"""SELECT * FROM ..."""` |
| `var` when type is obvious | `var users = new ArrayList<User>();` |
| `List.of()`, `Map.of()` for immutable collections | `var params = Map.of("key", value);` |
| Stream `.toList()` (Java 16+) | `users.stream().filter(...).toList();` |
| `Optional` as return type | `Optional<UnitCategory> getUnitCategory(String code)` |
| Factory methods on DTOs | `NoteResponse.fromNote(entity)` |
| `Mono.defer()` for lazy evaluation | `switchIfEmpty(Mono.defer(() -> fetchFromDb()))` |
| `@JsonIgnoreProperties(ignoreUnknown = true)` | On all models and DTOs |
| Functional composition | `Function<User,User> enrich = f1.andThen(f2);` |

### Discouraged

| Pattern | Why | Use Instead |
|---------|-----|-------------|
| `@Autowired` on fields | Not testable, hides dependencies | Constructor injection |
| `new` inside service methods | Tight coupling | Factory methods, DI |
| `.block()` in reactive code | Blocks event loop, defeats purpose of WebFlux | `.flatMap()`, `.map()` |
| `Thread.sleep()` | Blocks thread | `Mono.delay()` |
| Raw `Exception` / `RuntimeException` | Loses context | `ValidationException` |
| God class (> 500 lines) | Violates SRP | Split by responsibility |
| Mutable shared state | Thread-safety issues | Immutable objects, cache |
| `Optional` as method parameter | Confusing API | Overloaded methods or `@Nullable` |
| `null` returns | NPE risk | `Mono.empty()`, `Optional.empty()` |
| String concatenation in queries | N1QL injection risk | Parameterized queries |
| Logging inside constructors | Noise, startup overhead | Log in business methods |
| `@SuppressWarnings` without justification | Hides real issues | Fix the warning |

---

## Appendix C: Java 21 Feature Adoption Matrix

| Feature | JEP | Status | Adopt in New Code | Migrate Existing |
|---------|-----|--------|-------------------|-----------------|
| Records | 395 | Stable | YES — all new DTOs, configs | Gradually, starting with response DTOs |
| Sealed Classes | 409 | Stable | YES — domain hierarchies | When refactoring type switches |
| Pattern Matching for `instanceof` | 394 | Stable | YES — replace all cast patterns | On touch |
| Pattern Matching for `switch` | 441 | Stable | YES — replace if/else chains | When modifying switch blocks |
| Text Blocks | 378 | Stable | YES — queries, templates | On touch |
| `var` | 286 | Stable | YES — when type is obvious | Optional |
| Virtual Threads | 444 | Stable | CONDITIONAL — blocking tasks only | Not needed with WebFlux |
| Sequenced Collections | 431 | Stable | YES — `SequencedMap` when order matters | When order bugs found |
| Foreign Function & Memory | 442 | Preview | NO — wait for stable | N/A |
| String Templates | 459 | Preview | NO — wait for stable | N/A |
| Scoped Values | 446 | Preview | NO — wait for stable | N/A |

### Virtual Threads Guidance

WebFlux services already achieve non-blocking I/O via the event loop. Virtual threads are useful when:
1. You have **blocking legacy code** (JDBC, file I/O) that can't be made reactive
2. You need to **interop with blocking libraries** (e.g., some Hazelcast operations)
3. You're building a **servlet-based (non-WebFlux) service**

```java
// Use virtual threads for blocking operations instead of boundedElastic
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    var future = executor.submit(() -> blockingOperation());
    return future.get();
}

// Or wrap in Mono for reactive integration
Mono.fromCallable(() -> blockingOperation())
    .subscribeOn(Schedulers.fromExecutor(Executors.newVirtualThreadPerTaskExecutor()));
```

---

## Appendix D: Checklist for New Service

### Project Setup
- [ ] Java 21 toolchain configured
- [ ] Spring Boot 3.4+ with WebFlux (Netty)
- [ ] `starter-common-web` core module dependency
- [ ] Spotless + Checkstyle + JaCoCo configured
- [ ] `.githooks/` directory with pre-commit hook
- [ ] `DEVELOPMENT.md` documenting build commands, environment setup
- [ ] `CLAUDE.md` for AI-assisted development context
- [ ] `gradle.properties.example` with Nexus credential placeholders

### Configuration
- [ ] `application.yml` with externalized config via env vars
- [ ] Actuator endpoints exposed at `/adm/actuator/*`
- [ ] Health probes enabled (liveness, readiness, startup)
- [ ] Graceful shutdown configured
- [ ] CORS configured
- [ ] Swagger/SpringDoc configured at `/adm/swagger-ui.html`

### Architecture
- [ ] All controllers extend `BaseController` or `SecureController`
- [ ] All responses wrapped in `ApiResponse<T>`
- [ ] Service layer with interfaces where appropriate
- [ ] DAO layer with Hazelcast cache integration
- [ ] Domain models extend `CouchbaseEntity`
- [ ] DTOs with Jakarta validation
- [ ] Custom validators for domain-specific rules

### Quality
- [ ] 80% minimum test coverage (instruction + branch)
- [ ] Controller tests with `@WebFluxTest` + `WebTestClient`
- [ ] Service tests with `@ExtendWith(MockitoExtension.class)` + `StepVerifier`
- [ ] DAO tests with mocked Couchbase SDK
- [ ] `TestConfig` and `TestUtils` classes

### Observability
- [ ] Structured logging with traceId/spanId
- [ ] Micrometer metrics for key operations
- [ ] `@TimedOperation` on critical service methods
- [ ] Prometheus endpoint exposed

### Security
- [ ] JWT authentication for protected endpoints (if applicable)
- [ ] Input validation at controller boundary
- [ ] Parameterized queries (no string concatenation)
- [ ] No secrets in source code or YAML

### CI/CD
- [ ] Snyk vulnerability scanning
- [ ] SonarQube quality gate
- [ ] Semantic versioning with conventional commits
- [ ] Nexus artifact publishing

---

> **Document Maintainers:** Backend Engineering Team
>
> **Review Cadence:** Quarterly or when major framework upgrades occur
>
> **Feedback:** File issues in the shared standards repository or raise during team retrospectives
