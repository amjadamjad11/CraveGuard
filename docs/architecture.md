# CraveGuard — Architecture

## System Overview

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────┐
│  Flutter Mobile   │────▶│  FastAPI Backend  │────▶│  SQLite/     │
│  (Dart/Material3) │◀────│  (Python 3.12)   │◀────│  PostgreSQL  │
└──────────────────┘     └──────────────────┘     └──────────────┘
        │                        │
        │                        ▼
        │                 ┌──────────────┐
        │                 │  LLM API     │
        │                 │  (Optional)  │
        │                 └──────────────┘
        ▼
  ┌──────────────┐
  │  OS Services │
  │  - Geofence  │
  │  - Notifs    │
  │  - Location  │
  └──────────────┘
```

## Mobile Architecture (Flutter)

### State Management: Riverpod
- Providers for each feature domain
- AsyncNotifier for async state
- StateNotifier for complex state
- Provider for services/repositories

### Navigation: GoRouter
- Declarative routing
- Auth-aware redirects
- Nested navigation for tabs

### Layers
1. **Presentation** — Screens, widgets, design system
2. **Providers** — State management, business logic
3. **Repositories** — Data access abstraction
4. **Services** — API calls, local storage, platform services
5. **Models** — Data classes

## Backend Architecture (FastAPI)

### Layers
1. **API** — Route handlers, request/response
2. **Schemas** — Pydantic validation models
3. **Services** — Business logic
4. **Models** — SQLAlchemy ORM models
5. **Core** — Config, security, database

### AI/Personalization
- **Risk Scoring** — Weighted algorithm for location risk
- **Intervention Engine** — Feedback-based ranking with explore/exploit
- **CraveCoach** — LLM-powered chat with fallback responses

### Database
- SQLite for development (async via aiosqlite)
- PostgreSQL-compatible models for production
- Alembic migrations
