# 🚀 Publishing & Deployment Guide

Follow this guide when preparing to release the **I Like It** app to the Google Play Store or Apple App Store.

## ✅ Pre-Publish Checklist
- [ ] **App Icon:** Generate release icons using the `flutter_launcher_icons` package.
- [ ] **Package Name / Bundle ID:** Ensure the iOS Bundle ID and Android Package name reflect your brand (update via `android/app/build.gradle` and Xcode).
- [ ] **Remove Debug Code:** Ensure `print` statements are removed or ignored in production.
- [ ] **Environment File:** Your production `.env` must be bundled with the app, securely loaded, and point to the **Production Supabase Environment**.

## 🍏 iOS Release Requirements
1. **App Tracking Transparency (ATT):** If using analytics, ensure `NSUserTrackingUsageDescription` is properly set in `ios/Runner/Info.plist`.
2. **Permissions:** Ensure camera/network descriptions in `Info.plist` perfectly explain *why* the app needs them.
3. **Build Command:**
   ```bash
   flutter build ipa --release
   ```
4. Upload to TestFlight/App Store Connect using Xcode or Transporter.

## 🤖 Android Release Requirements
1. **Keystore Configuration:** Generate a secure upload keystore and map the `key.properties` file inside `android/` per [Flutter Docs](https://docs.flutter.dev/deployment/android).
2. **Network Security Config:** If allowing HTTP links in your webview/browser redirects, ensure `usesCleartextTraffic` is handled safely.
3. **Build Command:**
   ```bash
   flutter build appbundle --release
   ```
4. Upload the generated `.aab` file from `build/app/outputs/bundle/release/` to the Google Play Console.

## 🎨 Store Asset Requirements
When submitting to the stores, ensure you have:
- **App Icon:** 1024x1024px PNG (No alpha channel for iOS).
- **Screenshots:** At least 3-5 screenshots showing the Folders, Links, and Theme settings. 
  - *iOS:* 6.5" and 5.5" displays.
  - *Android:* Phone and 7" tablet sizing.
- **Privacy Policy:** Must be hosted on a live URL and linked in both app stores explicitly stating how emails and bookmarks are stored.
