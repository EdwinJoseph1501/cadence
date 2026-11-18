---
name: macos-integration
description: Use this skill when implementing, modifying, or testing native macOS integrations including UNUserNotificationCenter alerts, window lifecycle, bundle identity, and MenuBarExtra.
---

# macOS Native Integration for Cadence

## Purpose
Seamlessly integrate Cadence with macOS system features—notifications, window lifecycle, menu bar presence, and app bundle packaging—while respecting system privacy, power management, and human interface guidelines.

## When to Use
- Working on Phase 5 milestones (Native macOS Integration).
- Implementing notification triggers with `UserNotifications` (`UNUserNotificationCenter`).
- Managing window level (`.floating` always-on-top) and window close/hide lifecycle.
- Adding or configuring `MenuBarExtra` for status item countdown display.
- Configuring bundle identifier (`com.cadence.timer`) and macOS `Info.plist` attributes.

## Practical Workflow
1. **Application Identity & Bundle Metadata**:
   - Bundle Identifier: `com.cadence.timer`.
   - Maintain `Info.plist` template in `scripts/build-app.sh` with correct versioning, category (`public.app-category.productivity`), and minimum system version (macOS 14.0).
2. **Native System Notifications**:
   - Request authorization: `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])`.
   - Schedule completion notification with `UNTimeIntervalNotificationTrigger` or immediate post upon timer finish.
   - Ensure notifications deliver even when the application is minimized, backgrounded, or behind other windows.
3. **Window Lifecycle Management**:
   - Support window closing without quitting the app (standard macOS document/utility app behavior).
   - Reopen the main window when clicking the Dock icon (`applicationShouldHandleReopen:hasVisibleWindows:`).
   - Evaluate optional floating utility panel behavior (`NSWindow.Level.floating`).
4. **Menu Bar Integration (`MenuBarExtra`)**:
   - Implement lightweight `MenuBarExtra` showing live minutes/seconds or visual icon state.
   - Synchronize menu bar state with main window timer store.

## Project Constraints
- Minimum macOS target: macOS 14.0 (Sonoma).
- No third-party notification or tray libraries. Use only `UserNotifications` and SwiftUI native `MenuBarExtra`.

## Verification Expectations
- Bundle verification via `codesign -d --entitlements - build/Cadence.app` and `plutil -lint`.
- Test notifications fire accurately when the timer reaches zero while Cadence is in the background.

## Common Mistakes to Avoid
- **Ignoring Notification Permission Rejection**: App must function gracefully even if the user denies notification permissions.
- **Terminating on Window Close**: macOS users expect utilities with menu bar extras to remain running when their window is closed.
- **Excessive Menu Bar Redraws**: Inefficient view updates in the menu bar can waste battery. Throttle menu bar text updates to 1-second intervals.
