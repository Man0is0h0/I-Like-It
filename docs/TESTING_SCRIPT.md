# 🧪 Advanced User Acceptance Testing (UAT) & Quality Assurance Plan

This document serves as the absolute source of truth for mandatory manual testing routines. These rigorous test scripts must be fully executed and passed before authorizing any major release to the Google Play Store or Apple App Store.

It verifies the core user journey, ensures critical system stability, and checks for edge cases in network degradation, invalid user inputs, and background sync continuity.

---

## 🛡️ Preparation Phase

Before beginning:
1. Ensure the app is fully deleted from the testing device (to clear previous SecureStorage and SQLite data).
2. Install a completely fresh release build (`flutter build apk --release` or `flutter build ipa --release`).
3. Have at least one valid, accessible email inbox ready to receive OTPs.
4. Have a secondary device or simulator ready to test the dual-device cloud synchronization.

---

## 🧪 Phase 1: Authentication & Onboarding Constraints

### Test 1.1: First-Time Initialization
- **Action:** Open the fresh app installation. Enter a completely new, valid email address and click 'Send OTP'.
- **Verification:** Ensure the UI correctly transitions to a loading state. Verify an email containing a 6-digit code arrives via the Edge Function within 10 seconds.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 1.2: Invalid OTP Handling
- **Action:** Enter an intentionally incorrect 6-digit OTP code on the verification screen.
- **Verification:** The app must NOT crash. It must display a clear, readable SnackBar or Dialog indicating "Invalid Code" and allow the user to immediately try again.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 1.3: Successful Login & Database Provisioning
- **Action:** Enter the correct OTP.
- **Verification:** The app successfully validates the JWT, stashes the tokens in SecureStorage, creates a new row in the Supabase `users` table, and cleanly navigates the user to the (empty) Folders Dashboard.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 1.4: Persistent Session (Memory Wipe)
- **Action:** Force close the app completely (swipe it away from the OS multitasking view). Relaunch the app.
- **Verification:** The app must instantly load the Folders Dashboard. It must absolutely not request an email or OTP again.
- **Status:** **[ ] Pass / [ ] Fail**

---

## 🧪 Phase 2: Core Offline Capabilities & CRUD Operations

**CRITICAL INSTRUCTION:** For Phase 2, please disable the Wi-Fi and Cellular Connection on your testing device to verify the offline-first architecture.

### Test 2.1: Folder Creation (Offline)
- **Action:** Tap the '+' Floating Action Button. Select a blue icon. Name the folder "Offline Tech Docs" and hit Save.
- **Verification:** The dialog dismisses beautifully, a success snackbar appears, and the new folder tile renders immediately in the grid without any endless loading spinners or network errors.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 2.2: Duplicate Constraint (Offline)
- **Action:** Attempt to create another folder explicitly named "offline tech docs" (testing lower-case matching).
- **Verification:** The creation is blocked locally. An explicit warning dialog informs the user that a folder with this name already exists.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 2.3: Entering Links (Offline Fallback)
- **Action:** Open "Offline Tech Docs". Add a new Link: `https://github.com/flutter/flutter`.
- **Verification:** Since the network is down, the web scraper will fail gracefully. The app must still insert the raw URL into SQLite, render a generic placeholder icon/title in the list, and not throw a fatal red screen or crash block.
- **Status:** **[ ] Pass / [ ] Fail**

---

## 🧪 Phase 3: Synchronization & Network Recovery

**CRITICAL INSTRUCTION:** Re-enable Wi-Fi and Cellular Connection on the testing device.

### Test 3.1: Background Cloud Sync Recovery
- **Action:** Resume active network connection. Pull down on the Folders List (trigger `RefreshIndicator`) or wait for the automatic sync timer.
- **Verification:** The local background worker pushes the offline changes to Supabase. Navigate to your Supabase Dashboard -> Table Editor -> `folders` and `links`. Verify that the "Offline Tech Docs" folder and the GitHub link have correctly populated the cloud tables.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 3.2: Standard Web Scraping
- **Action:** Inside the folder, add a new link: `https://en.wikipedia.org/wiki/Dart_(programming_language)`.
- **Verification:** The app rapidly reaches out, scrapes the meta tags, updates the UI dynamically, and displays the Wikipedia logo and the correct page title on the `LinkCard`.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 3.3: Advanced Scraper Verification (YouTube)
- **Action:** Add a highly protected link: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`.
- **Verification:** The app successfully bypasses standard 429 scraping bot-blocks using its specialized YouTube parser and cleanly displays the rich, high-resolution video thumbnail on the card.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 3.4: Dual Device Reflection (Cloud Downsync)
- **Action:** Take your secondary device (Device B). Install the app and log in using the exact same email/OTP.
- **Verification:** Within 5 seconds, Device B must download the remote Supabase rows, write them to its local SQLite, and render the "Offline Tech Docs" folder and both the Github and Wikipedia links exactly as they appear on Device A.
- **Status:** **[ ] Pass / [ ] Fail**

---

## 🧪 Phase 4: UI, UX, and Native Integrations

### Test 4.1: Seamless Theming Engine
- **Action:** Open the top right context menu. Navigate to Appearance settings. Rapidly switch from Light Mode -> Dark Mode -> Light Mode.
- **Verification:** All Glassmorphism containers, fonts, and background scaffold colors respond instantly and accurately without requiring an app restart or glitching the UI tree.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 4.2: Native OS Sharing Target
- **Action:** Tap the 3-dots context menu on the Wikipedia link card. Tap "Share".
- **Verification:** The native iOS `UIActivityViewController` or Android `Intent.ACTION_SEND` modal pops up completely populated with the URL, ready to be forwarded to SMS, WhatsApp, Mail, etc.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 4.3: Destructive Operations (Cascading Deletes)
- **Action:** Tap the 3-dots on the "Offline Tech Docs" folder and click Delete. Confirm the warning dialog.
- **Verification:** The folder instantly vanishes from the UI. After 10 seconds, check the Supabase Cloud console. Verify the folder row is deleted AND verify that all child links that lived inside it were destroyed via the database cascading foreign keys.
- **Status:** **[ ] Pass / [ ] Fail**

### Test 4.4: Hard Logout & Data Purge
- **Action:** Navigate to Settings > Logout. Confirm the massive destructive action.
- **Verification:** The user is logged out and returned to the Email Login screen. Critically inspect the local filesystem or attempt to bypass the auth screen—ensure the SQLite database on the device has been irreversibly truncated and destroyed (preventing local privacy leaks).
- **Status:** **[ ] Pass / [ ] Fail**

---

## 🐛 Defect Logging Protocol

If any of the above tests Result in a [Fail], execution must halt, and a formal Github Issue or Jira Ticket must be opened using this exact template format:

```text
**Failed Sequence:** Phase [X], Test [X.X] - [Name of Test]
**Device Under Test:** [e.g., iPhone 15 Pro, iOS 17.2 / Pixel 8, Android 14]
**Build Tested:** Release Candidate [v1.X.X]

**Exact Steps to Reproduce the Failure:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Stated Expected Behavior:** [What the test script said should happen]
**Observed Actual Behavior:** [Detail exactly what went wrong, including crash logs or visual glitches]
```

## ✍️ Final Release Sign-off

By signing below, the Lead QA tester formally guarantees that every single test in this document has been manually executed and resulted in a `[Pass]` on a physical release build on both an iOS and Android device.

**Lead QA / Tester Name:** _________________________

**Date of Full Execution:** _________________________

**Target Release Version:** _________________________

**Deployment Status:** [ READY FOR PUBLICATION / BLOCKED ]
