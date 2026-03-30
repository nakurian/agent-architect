# UI Architecture Standards

These standards apply to all frontend applications built through this framework.

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Next.js / React 18+ / TypeScript (strict mode) |
| Component Library | MUI 6 (Material UI) |
| Styling | Tailwind CSS 3 + MUI theme |
| Server State | React Query (TanStack Query) |
| Forms | React Hook Form + Zod validation |
| Tables | MUI DataGrid or AG Grid |
| Routing | Next.js App Router |
| Auth | OAuth2 / SSO |
| Component Dev | Storybook |

## Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│              {app-name} (Next.js)                        │
├──────────┬──────────┬──────────┬──────────┬─────────────┤
│ Feature  │ Feature  │ Feature  │ Feature  │  Feature    │
│    A     │    B     │    C     │    D     │     E       │
└────┬─────┴────┬─────┴────┬─────┴────┬─────┴──────┬──────┘
     │          │          │          │            │
     ▼          ▼          ▼          ▼            ▼
┌─────────────────────────────────────────────────────────┐
│              React Query (Server State Layer)             │
│  useFeatureA │ useFeatureB │ useFeatureC │ ...          │
├─────────────────────────────────────────────────────────┤
│              API Client (Axios / Fetch)                   │
│  {domain}Api.ts — typed client for all endpoints         │
├─────────────────────────────────────────────────────────┤
│              Backend Service (REST API)                   │
│  /api/{resources}                                        │
└─────────────────────────────────────────────────────────┘
```

The UI communicates with backend services via REST APIs. Use a BFF layer only when the backend does not provide the exact data shapes the UI needs; otherwise communicate directly with the domain service.

## Project Structure

```
src/
├── app/                               # Next.js App Router
│   ├── layout.tsx                     # Root layout with AppShell
│   ├── page.tsx                       # Default page / redirect
│   ├── {feature-a}/                   # Route per feature
│   │   └── page.tsx
│   ├── {feature-b}/
│   │   └── page.tsx
│   └── {feature-n}/
│       └── page.tsx
│
├── features/                          # Feature-based modules
│   ├── {feature-a}/
│   │   ├── {FeatureA}Page.tsx         # Page-level component
│   │   ├── {SubComponent}.tsx         # Feature-specific components
│   │   ├── {AnotherComponent}.tsx
│   │   └── hooks/
│   │       ├── use{FeatureA}.ts       # React Query: GET /api/{resources}
│   │       ├── useCreate{Resource}.ts
│   │       └── useUpdate{Resource}.ts
│   │
│   ├── {feature-b}/
│   │   ├── {FeatureB}Page.tsx
│   │   ├── {SubComponent}.tsx
│   │   └── hooks/
│   │       └── use{FeatureB}.ts
│   │
│   └── {feature-n}/
│       ├── {FeatureN}Page.tsx
│       └── hooks/
│           └── use{FeatureN}.ts
│
├── shared/
│   ├── components/
│   │   ├── AppShell.tsx               # Nav sidebar + header + content area
│   │   ├── NavSidebar.tsx             # Left nav with screen links
│   │   ├── ConfirmDialog.tsx          # Destructive action confirmation
│   │   └── DataTable.tsx              # Wrapper around MUI DataGrid
│   ├── api/
│   │   └── {domain}Api.ts            # Typed API client for all endpoints
│   ├── hooks/
│   │   └── useAuth.ts                # Auth context hook
│   └── types/
│       └── {domain}.ts               # TypeScript types matching API contracts
│
└── styles/
    └── theme.ts                      # MUI theme + Tailwind integration
```

## State Management

### Server State — React Query (TanStack Query)

All data from backend services is managed via React Query. No Redux, no Context for server state.

| Pattern | Implementation |
|---------|---------------|
| **Polling** | Configurable `refetchInterval` for near-real-time data updates |
| **Optimistic updates** | Toggle/update operations update UI immediately, roll back on error |
| **Cache invalidation** | Mutations invalidate related queries |
| **Stale-while-revalidate** | Show cached data immediately, refetch in background |
| **Error retry** | 3 retries with exponential backoff for transient failures |

### Local State

Minimal — only for UI-specific state:
- Active filters and sort order
- Modal open/close state
- Selected table rows (for bulk operations)
- Form field values (via React Hook Form)

## API Client

Single typed API client per domain in `shared/api/{domain}Api.ts`:

```typescript
// All endpoints typed, returns typed responses
const domainApi = {
  // List resources
  getResources: (params: ResourceParams) => ...,

  // CRUD operations
  getResource: (id: string) => ...,
  createResource: (data: CreateResourceRequest) => ...,
  updateResource: (id: string, data: UpdateResourceRequest) => ...,
  deleteResource: (id: string) => ...,

  // Batch operations
  batchGetResources: (ids: string[]) => ...,

  // Sub-resources
  getSubResources: (parentId: string, params: PaginationParams) => ...,
};
```

- Use Zod schemas for runtime validation of API responses
- Include `traceId` from `ApiResponse` in error logging
- Handle `ApiResponse<T>` envelope: extract `payload`, check `status`, surface `errors`

## UI Component Mapping

| UI Concern | Standard Approach |
|---|---|
| Sidebar nav | Screen-based navigation matching feature routes |
| Auth context | OAuth2 / SSO — consistent auth provider across applications |
| State management | React Query for server state, minimal local state |
| Data tables | MUI DataGrid — sortable, filterable, paginated |
| Forms | React Hook Form + Zod — create/edit modals, settings |
| Charts / progress | Custom components as needed (progress bars, status indicators) |
| Loading states | React Query loading/error states, skeleton components |
| Error handling | Toast notifications for mutations, inline error messages for forms |
| Dark mode | Support both themes via MUI theme provider |
| Storybook | Document all shared components |
| Deep links | URL encodes key context (e.g., entity + date + screen) for bookmarking and sharing |

## Key UI Behaviors

| Behavior | Implementation |
|----------|---------------|
| **Real-time data updates** | React Query with configurable polling interval |
| **Optimistic updates** | Toggle/status operations update UI immediately, roll back on error |
| **Bulk operations** | Table supports multi-select for bulk actions |
| **Audit trail** | All manual actions logged with user identity and timestamp |
| **Role-based access** | VIEWER (read-only), OPERATOR (manage), ADMIN (settings + overrides) |
| **Confirmation dialogs** | All destructive or override actions require confirmation |
| **Deep links** | URL encodes key parameters for bookmarking and sharing |
| **Export** | CSV and PDF export from list/table views |

## MUI + Tailwind Integration

MUI provides the component library (DataGrid, dialogs, selectors, form controls). Tailwind handles utility styling and layout.

- Use MUI's `ThemeProvider` for consistent theming across components
- Use Tailwind for spacing, layout, and responsive utilities
- Avoid conflicting styles — use MUI's `sx` prop for component-specific overrides, Tailwind for layout
- Configure Tailwind's `important` selector to avoid specificity conflicts with MUI

## Repository Separation

UIs are **separate repositories** from both the planning repo and the service repo:

- `{project}-{domain}-ui` — Admin UI (Next.js). Talks to the backend service REST API.
- `{project}-{domain}-service` — Backend service (Java/Spring Boot). Owns all business logic and data.
- `{project}-{domain}-context` — Planning repo. Contains specs, standards, contracts (no code).

## Testing

- **Unit tests**: Utility functions, hooks (with `renderHook`), Zod schemas
- **Component tests**: React Testing Library — render components with mocked React Query responses
- **Storybook**: Visual documentation for shared components
- **E2E**: Playwright for critical user journeys
