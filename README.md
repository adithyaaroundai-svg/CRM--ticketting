# AroundTally Ticketing Platform

A full-featured **Flutter + Supabase** enterprise support & ticketing platform built for AroundTally. It connects three delivery surfaces:

1. **Agent App**  Desktop/web/mobile app for Admins, Support Heads, Support Engineers, Accountants, Sales, HR, and other internal roles.
2. **Customer Portal**  Flutter web app for B2B clients to raise tickets, track progress, and manage their company profile.
3. **Tally Prime Plugin**  A TDL side-load that injects ticket creation directly into customers' Tally Prime installations via API-key authentication.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Features](#2-features)
3. [Tech Stack](#3-tech-stack)
4. [Project Structure](#4-project-structure)
5. [Supabase Schema](#5-supabase-schema)
6. [Getting Started](#6-getting-started)
7. [Running the App](#7-running-the-app)
8. [Default Credentials](#8-default-credentials)
9. [Key Modules](#9-key-modules)
10. [Security Notes](#10-security-notes)

---

## 1. Architecture Overview

```
Tally Plugin  Supabase REST/RPC  Customer Portal
                        
                  PostgreSQL + RLS
                  Realtime Channels
                  Storage Buckets
                        
                   Agent App (Flutter)
```

- **Flutter clients** share UI foundations (FlexColorScheme, Google Fonts, GoRouter, Lucide Icons).
- **Supabase** hosts PostgreSQL tables, Row-Level Security policies, RPC functions, storage buckets, and realtime channels.
- **Riverpod + Clean Architecture**  each feature has `domain` (entities, repos), `data` (Supabase services), and `presentation` (providers, pages, widgets).

---

## 2. Features

### Ticketing
- Create, assign, escalate, and close support tickets
- Role-based dashboards with real-time SLA tracking
- AMC vs Normal ticket queues
- Ticket comments (internal/external), service reports
- Billing status flow: `New  Open  In Progress  Resolved  BillRaised  BillProcessed`
- File attachments on tickets (screenshots, documents)
- Assignment history and audit log

### Team Chat
- **Global support chat**  real-time team messaging
- **All-AroundTally channel**  company-wide channel accessible to all roles
- **Direct messages**  1-to-1 private messaging between agents
- **Sales channel**  dedicated sales team channel
- Emoji reactions on messages (toggled, stored as JSONB in DB)
- GIF picker (Giphy CDN + Tenor API search)
- Emoji picker
- File & image attachments
- Voice notes (record & playback)
- Reply-to / thread support
- Message soft-delete
- Read receipts & unread badge counts
- Hover action bar (reply, react, delete)
- Unique sender name colors

### Profile
- Editable username, full name, Teams User ID
- Profile avatar upload (resized to 512512 JPEG)
- Display color selector
- Change password
- Support performance stats (for Support role)
- Data backup (Admin only)

### Customer & CRM
- Customer list with AMC details, expiry tracking
- Company profile management
- Contact phone numbers

### Sales & Productivity
- Deals pipeline board
- Proposal generator (PDF export)
- Productivity widgets
- Leads management

### Admin
- User management
- App settings
- Data backup & export

---

## 3. Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x (Dart 3.9) |
| State Management | Riverpod 3 + Riverpod Generator |
| Navigation | GoRouter 17 |
| Backend | Supabase (PostgreSQL + Realtime + Storage) |
| UI Components | FlexColorScheme, Lucide Icons, Google Fonts, fl_chart |
| Rich Text | flutter_quill |
| File Handling | file_picker, image_picker, image (resize) |
| Audio | record, audioplayers |
| PDF | pdf, printing |
| HTTP | http (GIF/Tenor API) |
| Local Storage | shared_preferences |
| Code Generation | build_runner, freezed, json_serializable |
| Windows Packaging | msix |

---

## 4. Project Structure

```
lib/
 core/
    design_system/       # Theme, colors, components, layout (MainLayout, sidebar)
    logging/             # App logger
    errors/              # Error handling
 features/
    auth/                # Login, Agent model, AuthNotifier, profile page
    tickets/             # Ticket entities, repository, providers, pages
    dashboard/           # Role-based dashboards (Admin, Support, Accountant, etc.)
    chat/                # Team chat, DMs, all-aroundtally channel, reactions
    customers/           # Customer list, forms, AMC management
    sales/               # Deals board, proposal generator
    productivity/        # Productivity widgets, notifications
    backup/              # Data backup service (Admin)
 main.dart                # App entry point, GoRouter, Supabase init
supabase/
 migrations/              # All SQL migration files (chronological)
assets/
 tally_manual.json
 company_logo.png
tally/                       # Tally Prime TDL plugin files
```

---

## 5. Supabase Schema

### Core Tables

| Table | Purpose |
|---|---|
| `agents` | Internal user accounts  `username`, `password`, `role`, `display_color`, `avatar_url`, `teams_user_id` |
| `customers` | B2B company records  AMC details, API keys for Tally plugin, contact info |
| `tickets` | Support tickets  priority, status, SLA timestamps, assigned agent |
| `ticket_comments` | Ticket conversation thread (internal/external flag) |
| `service_reports` | Digital job cards  resolution details, time spent |
| `audit_log` | Immutable event log for ticket lifecycle changes |
| `chat_messages` | All chat messages  content, file attachments, reactions (JSONB), reply threading |

### Storage Buckets

| Bucket | Purpose |
|---|---|
| `avatars` | Agent profile pictures |
| `chat_attachments` | Files sent in chat |
| `voice_notes` | Voice recordings sent in chat |

### Key RPC Functions

| Function | Description |
|---|---|
| `login_agent(p_username, p_password)` | Validates agent credentials, returns agent record |
| `create_ticket(...)` | Ticket creation from Tally plugin with API-key auth |
| `change_agent_password(...)` | Secure in-app password change |

---

## 6. Getting Started

### Prerequisites

- Flutter SDK `^3.9.x`  [install](https://docs.flutter.dev/get-started/install)
- Dart SDK `^3.9.2`
- A [Supabase](https://supabase.com) project
- (Optional) Tally Prime for the TDL plugin

### 1. Clone the repo

```bash
git clone https://github.com/your-org/aroundtally-ticketing.git
cd aroundtally-ticketing
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Set up Supabase

Run migrations in order from the `supabase/migrations/` folder in your Supabase SQL Editor:

```
20250524000000_initial_schema.sql         Base schema
20251124000000_update_schema_and_seed.sql  Seed data
... (all subsequent migration files in order)
20260624000000_add_agent_email.sql        Latest: teams_user_id column
```

Create storage buckets:
- `avatars` (public read)
- `chat_attachments` (public read, authenticated upload)
- `voice_notes` (public read, authenticated upload)

---

## 7. Running the App

```bash
# Windows desktop
flutter run -d windows

# Web (Chrome)
flutter run -d chrome

# macOS
flutter run -d macos
```

### Build for Windows (MSIX installer)

```bash
flutter pub run msix:create
```

---

## 8. Default Credentials

> These are seeded by `20251124000000_update_schema_and_seed.sql`. Change immediately in production.

| Role | Username | Password |
|---|---|---|
| Admin | `admin` | `admin123` |
| Support | `support` | `supp123` |
| Accountant | `accountant` | `acc123` |
| Moderator | `moderator` | `mod123` |

**Customer Portal** uses Supabase email/password auth per company.

**Tally Plugin** uses per-customer `api_key` stored in the `customers` table.

---

## 9. Key Modules

### Auth (`lib/features/auth/`)
- Custom agent auth via `login_agent` RPC (not Supabase Auth)
- `Agent` model with `id`, `username`, `fullName`, `role`, `displayColor`, `avatarUrl`, `teamsUserId`
- Session persisted to `SharedPreferences`
- Profile editing: username, full name, Teams User ID, avatar, display color, password

### Chat (`lib/features/chat/`)
- `ChatMessage` entity with `reactions` (JSONB `List<Map>`), `fileUrl`, `fileType`, `replyToMessageId`
- `ChatRepository`  Supabase CRUD + `toggleReaction` (adds/removes emoji per user)
- `ChatController` provider  `sendMessage`, `deleteMessage`, `toggleReaction`
- `AllAroundTallyUnreadCount`  realtime unread badge with last-seen timestamp tracking
- GIF picker: Giphy CDN preloaded + Tenor API search
- Emoji picker with quick reactions on hover

### Tickets (`lib/features/tickets/`)
- Full ticket lifecycle with SLA timers
- Role-gated views (Admin sees all, Support sees assigned, etc.)
- File attachment support (screenshots, docs)
- Service report generation

### Dashboard (`lib/features/dashboard/`)
- Role-specific KPI widgets using `fl_chart`
- Real-time updates via Supabase streams

---

## 10. Security Notes

> **This project uses MVP-level security. Harden before any production deployment.**

- Agent passwords are stored as **plaintext** in the `agents` table. Replace with bcrypt hashing via a Supabase Auth integration or custom RPC before go-live.
- RLS policies currently allow `anon` to access all tables. Tighten per-role before production.
- **Never commit** `.env`, `supabase/config.toml.local`, or any files containing the Supabase `service_role` key. The `.gitignore` excludes these.
- The `anonKey` in `main.dart` is the **public anon key**  safe to expose, but rotate if compromised.
- Tally API keys (`customers.api_key`) should be unique per customer and rotated when offboarding.

---

## Contributing

1. Fork the repo and create a feature branch.
2. Run `flutter analyze` and `flutter test` before opening a PR.
3. Follow the existing Clean Architecture folder structure.
4. Run `dart run build_runner build` after any Riverpod/Freezed model changes.

---

*Built with Flutter + Supabase by the AroundTally team.*
