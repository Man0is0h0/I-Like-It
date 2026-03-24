# 🧪 User Acceptance Testing (UAT) Plan

Use this manual testing sheet before every major release to verify the core user journey of **I Like It**.

## Core Features & UAT

### Test 1: First-Time Onboarding
- **Steps:** 
  1. Open a fresh install of the app. 
  2. Enter a brand new email address. 
  3. Wait for the OTP in your inbox and enter it.
- **Expected Result:** The app successfully logs in, provisions a new database row, and navigates to an empty Folder Screen.
- **[ ] Pass / [ ] Fail**

### Test 2: Persistent Login
- **Steps:** 
  1. Kill/Restart the app completely from memory.
- **Expected Result:** App instantly loads the Folder Screen without asking for an email again.
- **[ ] Pass / [ ] Fail**

### Test 3: Creating a Folder
- **Steps:** 
  1. Tap the '+' Fab on the Folder screen. 
  2. Select an icon. 
  3. Name it "Test UAT" and hit Save.
- **Expected Result:** A success snackbar appears, and the folder is instantly visible in the Grid without a loading screen interruption.
- **[ ] Pass / [ ] Fail**

### Test 4: Creating a Duplicate Folder
- **Steps:** 
  1. Try creating another folder named "Test uat" (different casing).
- **Expected Result:** Dialog blocks the save process and warns the user that the folder name exists.
- **[ ] Pass / [ ] Fail**

### Test 5: Standard Link Scraping
- **Steps:** 
  1. Enter the "Test UAT" folder. 
  2. Tap '+' to add a link. 
  3. Paste a standard blog or Wikipedia URL.
- **Expected Result:** App fetches the title, fetches an icon/image thumbnail, and displays it beautifully in the list.
- **[ ] Pass / [ ] Fail**

### Test 6: YouTube Scrape Bypass
- **Steps:** 
  1. Tap '+' and paste a valid YouTube video URL (`https://youtu.be/...`).
- **Expected Result:** App successfully bypasses standard 429 scraping blocks and pulls the high-quality YouTube thumbnail.
- **[ ] Pass / [ ] Fail**

### Test 7: Native Sharing
- **Steps:** 
  1. Tap the 3-dots icon on the newly saved YouTube link. 
  2. Tap "Share".
- **Expected Result:** The native iOS/Android share sheet pops up with the URL ready to send to other apps.
- **[ ] Pass / [ ] Fail**

### Test 8: Edit & Delete Flow
- **Steps:** 
  1. Tap 3-dots > Edit. Change the title. Save. 
  2. Tap 3-dots > Delete. Confirm delete.
- **Expected Result:** The title visibly updates. Deletion successfully removes the link permanently from the UI.
- **[ ] Pass / [ ] Fail**

### Test 9: Cloud Synchronization
- **Steps:** 
  1. Create a folder and a link on Device A. 
  2. Log in with the same email on Device B.
- **Expected Result:** Device B syncs down the folders and links seamlessly in the background.
- **[ ] Pass / [ ] Fail**

### Test 10: Theming & UI
- **Steps:** 
  1. Open the top-right Folder menu overlay. 
  2. Navigate to "Appearance" and switch between Dark/Light modes.
- **Expected Result:** The UI updates instantly across all GlassContainers seamlessly.
- **[ ] Pass / [ ] Fail**

### Test 11: Logout Cleanup
- **Steps:** 
  1. Go to Settings > Logout. Confirm.
- **Expected Result:** The user is logged out, the local SQLite database is fully wiped (links disappear), and the app returns to the Email Login screen.
- **[ ] Pass / [ ] Fail**

---

## 🐛 Bug Report Template
If a test fails, copy this template and create a ticket:

**Test Failed:** [Test Name / Number]
**Device/OS:** [e.g., iPhone 15, iOS 17.2 or Pixel 7, Android 14]
**Steps to Reproduce:**
1. 
2. 
**Observed Behavior:** [What actually happened?]
**Expected Behavior:** [What should have happened?]

## ✍️ Sign-off
**Tested By:** _________________________
**Date:** _________________________
**Release Version:** _________________________
**Status:** [ APPROVED / REJECTED ]
