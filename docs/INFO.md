# 🗺 Architecture & Codebase Info

A mapped cheat sheet to help you understand where specific features and logics live within the **I Like It** codebase.

## 🖥 App Entry & UI
| Feature | Location | Description |
|---------|----------|-------------|
| **Entry Point** | `lib/main.dart` | Initializes local DB, Supabase, Theme, and determines the initial routing route based on session state. |
| **Routing** | `lib/main.dart` | Uses base MaterialPageRoute logic for simplicity. |
| **Folders UI** | `lib/features/folders/` | Screens and dialogs for creating, rendering, and managing the main folder list (`folder_screen.dart`). |
| **Links UI** | `lib/features/links/` | Code for displaying the rich `LinkCard`, processing open graph metadata, and native sharing. |
| **Settings / Admin** | `lib/features/settings/` & `admin/` | UI for theming, logout, and admin overviews. |

## ⚙️ Core Logic & Services
| Feature | Location | Description |
|---------|----------|-------------|
| **Authentication Flow** | `lib/features/onboarding/initial_setup_screen.dart` | Handles the UI logic for entering an email, waiting for the OTP, and verifying the session. |
| **Session Manager** | `lib/core/auth/user_session_manager.dart` | Singleton that securely stores the active User ID and Email via `flutter_secure_storage`. |
| **Offline Database** | `lib/core/database/database_helper.dart` | The local SQLite repository. Stores folders and links locally to allow full offline capability. |
| **Cloud Sync Engine** | `lib/core/sync/sync_manager.dart` | Background queue that compares local SQLite timestamps with Supabase to push/pull offline changes. |
| **Link Metadata Scraper** | `lib/core/utils/metadata_extractor.dart` | Makes HTTP calls to target URLs to extract `og:title`, `<title>`, `og:image`, and Apple touch icons. |

## 🎨 Theme & Utilities
| Feature | Location | Description |
|---------|----------|-------------|
| **App Theme Styles** | `lib/theme/app_theme.dart` | Contains core color definitions, text themes, and input decorations. |
| **Theme Manager** | `lib/core/theme/theme_manager.dart` | Listens to system changes and allows users to persist Dark/Light mode overrides. |
| **Glassmorphism Base** | `lib/core/widgets/glass_container.dart` | The custom frosty translucent layout container used heavily throughout the cards and UI. |
| **String Utilities** | `lib/core/utils/url_utils.dart` | Formatters for timestamps and cleanly parsing domains from raw URLs. |

## ☁️ Cloud & Backend
| Feature | Location | Description |
|---------|----------|-------------|
| **SQL Schema** | `project-backend/schema.sql` | The single source of truth for the cloud PostgreSQL database structure and row-level security. |
| **Remote Datasource** | `lib/core/sync/remote_datasource.dart` | The abstraction layer that talks *directly* to Supabase from Flutter. |
| **Edge Function (OTP)** | `project-backend/supabase/functions/send-otp/` | The Deno typescript function that catches login auth events and fires real emails via Nodemailer. |
