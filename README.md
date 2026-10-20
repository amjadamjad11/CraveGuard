# CraveGuard 🛡️

**AI-Powered Personalized Smoking Cessation App**

CraveGuard helps people understand their smoking habits, recognize triggers, reduce smoking, and work towards quitting through personalized and compassionate AI support.

## Features

- 🎯 **Personalized Onboarding** — Multi-step survey to understand habits, triggers, and goals
- 📊 **Smoking & Craving Tracker** — Log episodes with mood, trigger, and intensity tracking
- 🗺️ **Risk Map** — Identify and manage high-risk smoking locations with geofencing simulation
- 🤖 **CraveCoach AI** — Conversational AI assistant with adaptive keyword + LLM fallback coping strategies
- 💰 **Savings Tracker** — Track money saved in ₹ and set personal financial goals
- 📈 **Progress Dashboard** — Trend charts, milestone badges, and habit analytics
- 💪 **Intervention Engine** — Explainable ranking with explore/exploit learning from user feedback
- 🏠 **Motivation Vault** — Personal reasons to quit, affirmations, and media
- 👥 **Trusted Support** — Privacy-first contact support system with previewed SOS templates
- 🔔 **Smart Notifications** — Configurable, discreet reminders with consent control
- 🎨 **Design System & Widgets** — Reusable component library (`CgCard`, `CgProgressRing`, `CgStatCard`, `CgShimmerLoading`, `CgEmptyState`, `CgErrorState`)
- 🛡️ **About & Helpline Resources** — Built-in national quitline (1800-11-2356), health resources, and disclaimers

## Tech Stack

### Mobile (Flutter)
- Flutter 3.44 / Dart 3.12
- Material 3 with custom design system
- Riverpod state management
- GoRouter navigation
- Dio HTTP client
- fl_chart for data visualization
- Local notifications

### Backend (Python)
- FastAPI
- SQLAlchemy (async) with SQLite/PostgreSQL
- Pydantic validation
- JWT authentication
- Alembic migrations
- Configurable LLM API for AI chat

## Getting Started

### Prerequisites
- Flutter SDK 3.44+
- Python 3.12+
- pip

### Backend Setup

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env  # Edit with your settings

# Run migrations
alembic upgrade head

# Seed default data
python -m app.seed_data

# Start server
uvicorn app.main:app --reload --port 8000
```

### Mobile Setup

```bash
cd mobile
flutter pub get
flutter run
```

### Demo Mode

The app includes a fully functional demo mode that works without a backend connection. Toggle it from:
- Login screen → "Try Demo Mode" button
- Settings → Demo Mode toggle

Demo mode provides realistic sample data for all features.

### Environment Variables

Copy `backend/.env.example` to `backend/.env` and configure:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Database connection string | `sqlite+aiosqlite:///./craveguard.db` |
| `SECRET_KEY` | JWT secret key | (required) |
| `LLM_API_KEY` | API key for LLM chat | (optional - uses fallback) |
| `LLM_API_URL` | LLM API endpoint URL | (optional) |
| `DEMO_MODE` | Enable demo mode globally | `false` |

## Project Structure

```
craveguard/
├── mobile/                 # Flutter mobile app
│   ├── lib/
│   │   ├── app/           # App widget, shell
│   │   ├── core/          # Constants, extensions
│   │   ├── theme/         # Colors, typography, theme
│   │   ├── routing/       # GoRouter configuration
│   │   ├── models/        # Data models
│   │   ├── services/      # API, auth, storage services
│   │   ├── providers/     # Riverpod providers
│   │   ├── widgets/       # Reusable design system widgets
│   │   └── features/      # Feature modules
│   │       ├── onboarding/
│   │       ├── home/
│   │       ├── smoking_tracker/
│   │       ├── craving_support/
│   │       ├── risk_map/
│   │       ├── ai_chat/
│   │       ├── progress/
│   │       ├── savings/
│   │       ├── motivation_vault/
│   │       ├── trusted_support/
│   │       └── settings/
│   └── test/
├── backend/                # FastAPI backend
│   ├── app/
│   │   ├── api/           # Route handlers
│   │   ├── core/          # Config, security, database
│   │   ├── models/        # SQLAlchemy models
│   │   ├── schemas/       # Pydantic schemas
│   │   ├── services/      # Business logic
│   │   └── ai/            # AI chat, risk scoring, interventions
│   ├── migrations/        # Alembic migrations
│   ├── tests/             # Backend tests
│   └── requirements.txt
├── docs/                   # Documentation
└── README.md
```

## Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.

## Privacy & Safety

- **No background location tracking** without explicit consent
- **No automatic contact messaging** — all support messages require user approval
- **Discreet notifications** — no addiction info on lock screen by default
- **Data minimization** — only essential data is collected
- **Secure storage** — tokens stored in platform secure storage
- **User control** — all data can be exported or deleted

## Limitations

- Map features require Google Maps API key for full functionality (simulation mode available)
- AI chat uses LLM API when configured; fallback coping strategies available without it
- Geofencing requires device support; simulation tool provided for testing
- This app provides supportive tools, not medical advice. Users are encouraged to consult healthcare professionals.

## Testing

```bash
# Backend tests
cd backend
pytest

# Flutter tests
cd mobile
flutter test

# Flutter analysis
flutter analyze
```

## License

This project is created for educational and hackathon purposes.
