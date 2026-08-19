# Device & Environment Reference

> Last updated: 2026-07-27
> Purpose: Quick reference for debugging, testing, and reproducing issues across devices.

---

## 🖥️ Development Machine

| Property | Value |
|---|---|
| OS | Windows 10 (Build 26200) |
| Flutter SDK | `D:\app dev\flutter_windows_3.35.2-stable\flutter` |
| Flutter Version | 3.35.2 (stable) |
| Dart | Bundled with Flutter |
| Java | JDK 23.0.2 (`C:\Program Files\Java\jdk-23`) |
| Android SDK | `D:\app_dev_sdk` |
| Android SDK Version | 36.1.0-rc1 |
| Android Platform | android-36 |
| Build Tools | 36.1.0-rc1 |

---

## 📱 Physical Device (Primary Test Device)

| Property | Value |
|---|---|
| Device Name | RMX3710 (Realme) |
| Connection ID | `B6YDAMWCQGZXL74P` |
| Architecture | android-arm64 |
| Android Version | Android 15 (API 35) |
| Type | Physical (USB) |

**Run on this device:**
```powershell
flutter run -d B6YDAMWCQGZXL74P
```

---

## 📟 Emulators

### Nexus 7 Tablet (7-inch)

| Property | Value |
|---|---|
| AVD Name | `Nexus7_Tablet` |
| Device | Nexus 7 2013 (Google) |
| Screen Size | **7.02 inches** |
| Resolution | 1200 × 1920 px |
| Density | 320 dpi (xhdpi) |
| Android API | 36 (Google Play) |
| Architecture | x86_64 |
| SD Card | 512 MB |
| AVD Path | `C:\Users\misal\.android\avd\Nexus7_Tablet.avd` |

**Launch emulator:**
```powershell
D:\app_dev_sdk\emulator\emulator.exe -avd Nexus7_Tablet -gpu auto
```

**Run app on emulator:**
```powershell
flutter run -d emulator-5554
```

**Take screenshot:**
```powershell
flutter screenshot -d emulator-5554 --out screenshot.png
```

**ADB screenshot:**
```powershell
D:\app_dev_sdk\platform-tools\adb.exe -s emulator-5554 shell screencap -p /sdcard/screen.png
D:\app_dev_sdk\platform-tools\adb.exe -s emulator-5554 pull /sdcard/screen.png C:\Users\misal\Desktop\screen.png
```

---

## 🌐 Web Targets

| Device | ID | Notes |
|---|---|---|
| Chrome | `chrome` | Primary web testing |
| Edge | `edge` | Secondary web testing |

**Run on Chrome:**
```powershell
flutter run -d chrome
```

---

## ⚙️ Useful Commands

```powershell
# List all connected devices
flutter devices

# List all emulators (running or not)
flutter emulators

# Check environment health
flutter doctor -v

# Kill all running Gradle daemons (fixes stuck builds)
.\gradlew --stop

# Clear build cache (fixes weird build errors)
flutter clean
flutter pub get

# Check ADB devices
D:\app_dev_sdk\platform-tools\adb.exe devices
```

---

## 🐛 Known Issues & Notes

| Issue | Device | Status | Fix |
|---|---|---|---|
| Splash screen pillarboxed | Nexus 7 Tablet | Known | Splash image sized for phone; cosmetic only |
| First Gradle build very slow | All | Known | Wait 5-15 mins on first run; subsequent builds are fast |

---

## 📦 App Info

| Property | Value |
|---|---|
| App Name | iLikeIt |
| Package Name | `com.ilikeit.app` |
| Flutter Project Dir | `i_like_it/` |
| Min SDK | Per `flutter.minSdkVersion` |
| Target SDK | Per `flutter.targetSdkVersion` |
| Signing Config | `android/key.properties` |

