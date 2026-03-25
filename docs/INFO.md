# 🗺 Comprehensive Architecture & Codebase Info

This document provides an in-depth, mapped overview of the **I Like It** application architecture. It is designed to act as a cheat sheet for developers to rapidly understand where specific features, state managers, and logic modules live within the codebase, as well as the design philosophy behind them.

---

## 🏗️ 1. High-Level Architecture Pattern

The application follows a heavily modular, feature-based architecture (often referred to as feature-first or slice-based routing). Instead of grouping files by type (e.g., all `models`, all `screens`, all `controllers`), the codebase is separated by domain features. 

This ensures that everything related to "Folders," for example, lives entirely within the `features/folders/` directory, drastically reducing cognitive load when navigating the project.

---

## 🖥️ 2. App Entry & User Interface

The UI layer is written in Flutter using a heavily customized, glassmorphism-inspired Material Design language.

| Domain Area | File / Directory | Detailed Responsibility |
|-------------|------------------|-------------------------|
| **Entry Point and Initialization** | `lib/main.dart` | The very first executed code. It initializes Flutter engine bindings, starts the local SQLite database (`DatabaseHelper`), initializes the Supabase client, applies the global `ThemeManager`, and routes the user based on active session state. |
| **Routing Protocol** | `lib/main.dart` | The app uses standard `MaterialPageRoute` push/pop mechanics for maximum compatibility and simplicity instead of deep-linking reliant routers (like GoRouter), which are unnecessary for this offline-first architecture. |
| **Folders Management** | `lib/features/folders/` | Contains the `folder_screen.dart` (the main dashboard). Also includes sub-components for the "Create Folder" bottom sheet dialogs, icon pickers, and color assignment tools. |
| **Links Management** | `lib/features/links/` | Contains `link_screen.dart` to view specific lists. Critical files include `link_card.dart` which uniquely handles rich Open Graphic meta-data display, image caching fallbacks, and the gesture detector for raw native sharing. |
| **Settings & Admin Panel** | `lib/features/settings/` | User settings panel (logout, appearance override). Includes admin-only views to visualize system health, active users, and backend analytics securely retrieved from Supabase. |

---

## ⚙️ 3. Core Logic & Background Services

This layer acts as the brain of the application. It handles data abstraction, synchronization, secure storage, and network requests independently of the UI.

| Domain Area | File / Directory | Detailed Responsibility |
|-------------|------------------|-------------------------|
| **Auth & Onboarding** | `lib/features/onboarding/initial_setup_screen.dart` | Manages the UI state machine for authentication. Transitions the user from "Enter Email" -> "Check Inbox" -> "Enter OTP" based on reactive streams. |
| **Session State Management** | `lib/core/auth/user_session_manager.dart` | A singleton pattern wrapper around `flutter_secure_storage`. It securely encrypts and stores the active JWT, User UID, and Email Address, preventing the need to re-authenticate when the app is restarted. |
| **Offline SQLite Database** | `lib/core/database/database_helper.dart` | The absolute critical core of the app's offline-first design. All reads and writes hit this local SQLite repository first. It structures the tables locally mirrored from the cloud, enabling sub-millisecond load times regardless of network connectivity. |
| **Background Synchronization** | `lib/core/sync/sync_manager.dart` | A dedicated background worker queue. It constantly watches for local data changes, timestamp disparities, or 'dirty' flags on SQLite rows, and systematically pushes them to Supabase when network connectivity is detected. Conversely, it polls the backend for new data created on other devices. |
| **Metadata Web Scraper** | `lib/core/utils/metadata_extractor.dart` | A robust utility that processes raw HTTP GET requests against saved URLs. It parses the DOM to extract `<title>`, `<meta property="og:title">`, `<meta property="og:image">`, and Apple touch icons. Contains custom bypass headers for certain aggressive CDNs. |

---

## 🎨 4. Theme & Utility Abstractions

Reusable visual components and pure functions that are completely agnostic to business logic.

| Domain Area | File / Directory | Detailed Responsibility |
|-------------|------------------|-------------------------|
| **Global Theme System** | `lib/theme/app_theme.dart` | Defines the central `ThemeData`. Dictates primary, secondary, surface, and background colors. Instantiates the global `TextTheme` overrides using modern typography (e.g., Google Fonts). |
| **Runtime Theme Manger** | `lib/core/theme/theme_manager.dart` | Listens to the `PlatformDispatcher` for OS-level theme changes, but enables the user to forcefully override the local app setting via `SharedPreferences`. |
| **Glassmorphism Container** | `lib/core/widgets/glass_container.dart` | The signature visual element of the app. Applies a `BackdropFilter` with `ImageFilter.blur` layered under a translucent container with a stark white minimal border radius to create a frosted glass effect. |
| **Formatting Utils** | `lib/core/utils/url_utils.dart` | Regular expressions and string manipulators. Cleanses erratic URLs (adding `https://` where missing), standardizes ISO-8601 timestamps locally to human readable relative strings (e.g. "2 hours ago"). |

---

## ☁️ 5. Backend Infrastructure (Cloud Node)

The components hosted entirely on the server-side, enabling cross-device sync and security.

| Domain Area | File / Directory | Detailed Responsibility |
|-------------|------------------|-------------------------|
| **PostgreSQL Schema** | `project-backend/schema.sql` | The undisputed source of truth for the database. Contains table layouts, foreign key constraints (e.g., links cascading delete when a folder is deleted), and the rigorous Row Level Security (RLS) policies that prohibit direct API scraping by unauthorized identities. |
| **Datasource Abstraction** | `lib/core/sync/remote_datasource.dart` | The single boundary layer between Flutter and Supabase HTTP APIs. Translates local domain objects to JSON objects required by Supabase API inserts and updates, catching and formatting network exceptions. |
| **Deno Edge Function** | `project-backend/supabase/functions/send-otp/` | A stateless serverless function. Subscribes to Supabase Auth login events, formulates HTML email templates, and routes them securely through third-party SMTP providers (Gmail/Resend) without exposing API keys to the mobile client. |

---

## 📌 Summary Note on Offline-First Paradigm
Remember: In this application, **the local SQLite database is the master visual state**. The application *never* blocks the UI waiting for a Supabase network request to finish saving a link.
1. The user saves a link.
2. It writes to SQLite and immediately refreshes the UI.
3. The `SyncManager` flags it as 'dirty' and pushes it to the cloud invisibly in the background. 
Always adhere to this pattern when adding new features!
