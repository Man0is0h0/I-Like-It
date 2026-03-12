# I Like It - Complete Application Architecture & Documentation

This document serves as the comprehensive source of truth for the **I Like It** application, detailing its architecture, features, security protocols, and operational workflows.

---

## 1. High-Level Architecture
The application is a cross-platform mobile application built with **Flutter** (Frontend) and backed by **Supabase** (Backend as a Service). It focuses on managing, categorizing, and safely storing links and folders across devices with seamless offline-first support.

**Core Pillars:**
- **Frontend**: Flutter (Dart), utilizing Provider/State Management.
- **Local Storage**: SQLite (`sqflite`) for an offline-first caching experience.
- **Backend Core**: Supabase PostgreSQL database.
- **Backend Compute**: Supabase Edge Functions (Deno/Typescript).
- **Authentication**: Supabase Auth extended with a custom secure OTP system.

---

## 2. Feature Modules (Frontend - `lib/features/`)

The application is structured by feature sets to maintain clean separation of concerns.

### 2.1 Onboarding & Authentication (`onboarding/`)
- **Email OTP Authentication**: Users sign in or sign up exclusively via Email One-Time Passwords (OTPs).
- **Secure Recovery Codes**: On account creation, users are provided a 16-character recovery code.
    - *Security*: The backend stores both a one-way `recovery_hash` (for fast lookup) and an `encrypted_recovery_code` (AES-256 encrypted) so users can view their real code later if authenticated.
- **Session Management**: Securely handles JWTs and refresh tokens using `flutter_secure_storage`.

### 2.2 Folders (`folders/`)
- **Custom Organization**: Users can create, update, and manage folders with custom icons and names.
- **Smart Folders**: Virtual folders that aggregate specific constraints.
- **Automatic Categories**: Folders are assigned a `system_category`. If a user does not explicitly set one, it defaults to `other` until the Backend AI categorizer processes it.

### 2.3 Links (`links/`)
- **Link Management**: Users can save URLs into specific folders.
- **Metadata Extraction**: Utilizes `http` and `html` Dart packages to scrape web metadata (Title, Description, Favicon/OG Image) automatically upon saving a link.
- **Favorites**: Users can toggle a boolean `is_favorite` flag for quick access.

### 2.4 Share Extension (`share/`)
- **OS Integration**: Implements native Share Extensions (via `share_plus`) allowing users to save links directly from external apps (e.g., Chrome, Safari, Twitter) into the "I Like It" app without opening it manually.

### 2.5 Search (`search/`)
- **Global Search**: Allows querying across folder names, link titles, and link URLs simultaneously.

### 2.6 Admin Dashboard (`admin/`)
- **Role-Based Access Control (RBAC)**: Requires a `role = 'admin'` flag in the `users` table.
- **System Metrics**: Visualizes growth and analytics using `fl_chart`.
- **Insights**: Shows Total Users, Active Users (last 24h), Total Folders, Total Links, and a breakdown of System Categories distribution.

---

## 3. Backend Architecture (Supabase)

### 3.1 Database Schema (`schema.sql`)
- `users`: Extends Supabase Auth. Holds `role`, `encrypted_recovery_code`, `recovery_hash`, and `last_seen_at`.
- `folders`: Linked to users via Foreign Key. Supports soft-delete (`is_deleted`).
- `links`: Cascades on folder deletion.
- `email_otps`: Temporary table to hold OTP attempts.
- `debug_logs`: System logging table.

### 3.2 Security & Row Level Security (RLS)
The database operates under strict RLS constraints.
- **Default Rule**: `auth.uid() = user_id`. A user can only Select, Insert, Update, or Delete their own data.
- **Admin Override**: Users with the `admin` role are able to view system-wide data (required for the Admin Dashboard metrics).
- **Service Role Bypass**: Automated Edge Functions run with the Service Role key, bypassing RLS to process data (e.g., classifying folders for any user).

### 3.3 Remote Sync Strategy (`core/sync/`)
The application is designed to be offline-capable:
1. **Local Writes**: Data is written directly to SQLite (`sqflite`).
2. **Background Sync**: Changes are pushed to Supabase via `remote_datasource.dart`.
3. **Conflict Resolution**: Timestamps (`updated_at` / `last_sync_time`) are used to fetch only delta updates.

---

## 4. Edge Functions & Automation (Deno/TypeScript)

### 4.1 AI Folder Classification (`classify-folders`)
- **Purpose**: To keep user folders organized without manual effort.
- **Trigger**: Runs automatically every 30 minutes via a `pg_cron` database job.
- **Mechanic**:
    1. Fetches up to 10 folders where `system_category` is 'other' or null.
    2. Sends the folder name to the **Google Gemini Pro AI API**.
    3. Gemini returns a strictly formatted category string (e.g., 'tech', 'entertainment', 'finance').
    4. Updates the folder via the Supabase Client.

### 4.2 Email OTP Delivery (`send-otp`)
- **Purpose**: Delivers the 6-digit verification codes to users.
- **Trigger**: Invoked instantaneously by a Postgres Database Trigger (`on_auth_otp_request`) the moment a new row is inserted into the `email_otps` table. The trigger uses `pg_net` to fire a non-blocking asynchronous HTTP POST to the Edge Function.
- **Mechanic**:
    1. Receives the `email` and `otp_code` payload.
    2. Invokes the **Resend API** to format and deliver an HTML email template.
    3. Handles failure logging to the standard Output.

---

## 5. Security Protocols Summary
1. **No Client-Side Secrets**: Resend API and Gemini API keys strictly reside in Supabase Edge Functions environments.
2. **Denial of Wallet (DoW) Protection**: The `classify-folders` endpoint enforces a strict Authorization header check expecting the Supabase Service Role Key. If called publicly, it immediately rejects it with a 401 Unauthorized status.
3. **Recovery Code Encryption**: The plaintext 16-character recovery codes are never stored on the server. They are hashed for lookup and encrypted at rest with AES-256 using a hardcoded app secret. Only the authenticated Flutter client has the key to decrypt and reveal it.

---

This documentation comprehensively details the current structure, capabilities, and security topology of the **I Like It** application.
