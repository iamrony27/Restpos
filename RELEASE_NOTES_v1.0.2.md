# Rest POS v1.0.2 Release Notes

**Release Date:** October 29, 2026  
**Build Number:** 3  
**Package:** `com.restaurantpos.flutter_restaurant_pos`  
**Platform:** Android (Offline-First POS & Restaurant Management)

---

## 🛠️ Critical Fixes & Enhancements

### 1. 🔄 Multi-Tier Resilient Backup & Restore
- **Fixed "No backup file found" Error**: Resolved Android 10+ Scoped Storage MediaStore query restriction where `RELATIVE_PATH LIKE ?` failed across OEM devices.
- **Added SharedPreferences Mirror**: Automatically persists backup JSON directly in SharedPreferences mirror (`restpos_persisted_backup_json`), guaranteeing 100% immunity to Android file permission denials, SD card glitches, and Scoped Storage restrictions.
- **Added App-Specific Storage Fallback**: Backups are now also saved and read from `getExternalFilesDir(null)` (`/Android/data/.../files/`) and internal `filesDir`, where Android grants seamless read/write access without requiring user runtime permissions.
- **Enhanced Android Manifest**: Added `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (maxSdkVersion=28), and `android:requestLegacyExternalStorage="true"`.
- **4-Tier Restore Cascade**: Restore now checks `MediaStore Downloads` → `App External Files` → `App Internal Storage` → `SharedPreferences Mirror`, ensuring backups are immediately and reliably discoverable.

### 2. 🌓 Reactive Dark Theme Toggle Switch
- **Fixed Switch State Synchronization**: The Material 3 dark theme toggle switch in Settings now binds directly to `Theme.of(context).brightness == Brightness.dark`.
- **Eliminated Frozen Route Argument**: Fixed stale `widget.isDarkMode` route argument in `HomeShellScreen`, allowing the switch knob to toggle visibly between ON and OFF in real-time as the theme transitions.
- **Synchronized Bottom Navigation Bar**: Bottom navigation bar glassmorphism shadows and center button halo now react dynamically to theme switches.

### 3. 🏷️ Version Footer & Verification
- Updated bottom of Settings screen to **Rest POS v1.0.2 (Build 3)**.
- Full automated test suite passed (29/29 tests including accounting and multi-tier backup tests).
- Static analysis clean (0 errors, 0 warnings, 0 lints).
