# Planite

An AI-powered group scheduling app built with Flutter. Planite connects to Google Calendar, uses a conversational AI planner to find mutual availability across group members, and manages event proposals with accept/decline workflows.

Built for the **Cursor Hackathon 2026** by CMD-V-Cartel.

---

## Features

### AI Planner Chat
- Natural language event scheduling via text or voice input
- Conversational agent powered by Google Gemini on the backend
- Automatic group availability checking — suggests free windows when conflicts exist
- Tappable time slot suggestions that send follow-up requests to create proposals
- Speech-to-text via device microphone with real-time transcription

### Google Calendar Integration
- Native Google Sign-In with OAuth 2.0 (PKCE flow via Supabase)
- Two-way sync: events created in-app are pushed to Google Calendar
- Day view with Syncfusion Calendar, live current-time indicator
- Force-refresh on date selection for always-fresh data
- Manual event creation with date/time pickers

### Groups & Event Proposals
- Create groups, invite members by email, accept/decline invites
- Event proposal system: AI proposes a time → group members vote → confirmed events are pushed to everyone's Google Calendar
- Progress tracking with acceptance count and status badges (Pending / Confirmed / Cancelled)
- Member management with avatar stacks, role badges, and removal

### Auth
- Email/password registration and login
- Google Sign-In with Supabase identity linking
- Secure token storage with auto-refresh
- Onboarding flow for first-run experience

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart 3.9+) |
| **State Management** | Provider (ChangeNotifier) |
| **Routing** | go_router v17 |
| **Calendar** | Syncfusion Flutter Calendar |
| **Networking** | Dio |
| **Auth** | Supabase Auth + Google Sign-In (native iOS) |
| **Secure Storage** | flutter_secure_storage |
| **Voice Input** | record (mic capture) → backend STT |
| **Backend** | FastAPI (Python 3.12+) with Supabase PostgreSQL |
| **AI Engine** | Google Gemini (via backend) |
| **Calendar API** | Google Calendar API (via backend refresh tokens) |
| **Tunneling** | zrok (public API endpoint) |

---

## Project Structure

```
lib/
├── config/                   # Environment & OAuth config
├── features/
│   ├── ai_chat/              # AI planner: chat screen, agent repo, response models, widgets
│   ├── auth/                 # Login, signup, auth provider & repository
│   ├── calendar/             # Calendar screen, provider, repository, event model
│   ├── groups/               # Groups & invites, event proposals, member management
│   ├── home/                 # Main tabbed shell (Calendar / Groups / AI Planner)
│   └── onboarding/           # First-run onboarding screen
├── global-widgets/           # Reusable UI components
├── router/                   # go_router configuration & route constants
├── services/
│   ├── network/              # Dio client, API URLs, response models
│   └── storage/              # Secure token storage
├── utils/                    # Colors, themes
└── main.dart                 # App entry point & provider setup
```

---

## Getting Started

### Prerequisites

- Flutter SDK >= 3.9.2
- Xcode (for iOS builds)
- A `.env` file in the project root (see below)

### Environment Setup

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://kjzcqnidhltsapzvduos.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>
GOOGLE_CLIENT_ID_IOS=<your-google-client-id>
```

### Install & Run

```bash
# Install dependencies
flutter pub get

# Run on iOS simulator
flutter run

# Run on a physical device
flutter run --release
```

---

## API

The app communicates with a FastAPI backend at:

```
https://planiteinvite.share.zrok.io
```

Key endpoints:

| Endpoint | Purpose |
|----------|---------|
| `POST /auth/login` | Email/password login |
| `POST /auth/register` | Registration |
| `POST /auth/google/sync` | Push Google refresh token |
| `GET /calendar/events` | Fetch events for a date |
| `POST /calendar/events` | Create a calendar event |
| `POST /agent/interact/text` | AI agent text query |
| `POST /agent/interact` | AI agent voice query (multipart) |
| `GET /groups` | List user's groups |
| `POST /groups` | Create a group |
| `GET /event-proposals/group/{id}` | List proposals for a group |
| `POST /event-proposals/{id}/respond` | Accept/decline a proposal |

Full API documentation is in `lib/features/AGENTS.md`.

---

## Architecture

The app follows a **feature-first** architecture with clean separation:

- **Presentation** — Screens and widgets (Flutter `StatefulWidget` / `StatelessWidget`)
- **Controllers** — `ChangeNotifier` providers for reactive state
- **Repository** — Dio-based API clients, one per feature domain
- **Models** — Dart data classes with `fromJson` factories

Navigation uses `go_router` for top-level routes (onboarding → auth → home) and `IndexedStack` for the three main tabs within the home shell.

---

## Team

**CMD-V-Cartel** — Cursor Hackathon 2026

---

## License

This project was built for a hackathon and is not currently licensed for redistribution.
