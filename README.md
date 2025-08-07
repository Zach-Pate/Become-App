> **Note:** These files build perfectly. Please be very sparing in editing files to ensure that the build continues to work.

# Become - A Daily Planner App

This is a SwiftUI app that helps you plan your day. It features a vertical timeline where you can schedule and rearrange events.

## Features

*   **Seamless Day Navigation:** Replaced the manual swipe gesture with a `TabView` for a smooth, animated, and seamless transition between days. This also resolves gesture conflicts with event tiles.
*   **Dual-Mode Date Selection:** Navigate between days using either the horizontal menu at the top of the screen or by swiping left and right. The app automatically starts on the current date, which is centered and highlighted in the menu.
*   **Smart Scroll:** The schedule automatically scrolls to 6 AM when you open the app or switch between days, so you can start planning from the beginning of your day.
*   **Repeating Events:** Set events to repeat daily or on specific days of the week. The app intelligently displays repeating events on the correct days.
*   **Cross-Day Event Management:** You can now move events to different days. When adding or editing an event, a date picker is available to select the desired day.
*   **Aesthetic Pop-ups:** The "Add New Event" and "Edit Event" pop-ups are styled to be more visually appealing and no longer take up the entire screen.
*   **Add New Events:** A "+" button on the date selector bar opens a pop-up where you can create new events with a title, start time, end time, and category.
*   **Edit and Delete Events:** Long-press on an event to open a pop-up where you can edit its details or delete it. When deleting a repeating event, you can choose to delete just that single instance or the entire series.
*   **Event Categories:** Events can be assigned to categories, each with a unique color. The category picker is now sorted alphabetically and includes a new "Study" category.
    *   Appointment (Red)
    *   Errands (Yellow)
    *   Exercise (Green)
    *   Family (Pink)
    *   Meal (Orange)
    *   Meeting (Blue)
    *   Personal (Purple)
    *   Rest (Mint)
    *   Social (Teal)
    *   Study (Brown)
    *   Travel (Rust)
    *   Work (Indigo)
    *   Other (Gray)
*   **24-Hour Scrollable Timeline:** The main view is a vertical timeline that displays your full day's schedule. The time labels are now perfectly centered on their corresponding hour markers.
*   **Visual Snap Grid:** A faint grid of 10-minute increments provides a visual guide for event placement.
*   **Live Time Indicator:** A horizontal bar, anchored to the left edge of the screen, shows the current time and updates every minute. The indicator has been styled for better visibility.
*   **Intuitive, Real-Time Gestures:**
    *   Drag an event vertically to move it to a different time. The time display on the tile updates in real-time as you drag.
    *   Drag the top or bottom handles of an event to adjust its duration.
    *   Long-press an event to edit or delete it.
*   **Advanced Gesture Handling:** The app now correctly differentiates between scrolling the timeline and dragging an event, preventing accidental edits and providing a smoother user experience.
*   **Smooth Dragging:** Events now move and resize smoothly with your finger, without any jitter. The time display on the tile also updates in real-time.
*   **Velocity-Based Snapping:** Events now snap to a 10-minute grid when dragged or resized.
*   **Haptic Feedback:** The app provides haptic feedback when you're moving or resizing an event.
*   **Dynamic Tile Sizing:** Event tiles are sized proportionately to their duration.
*   **Adaptive Tile Content:** The event title and time are hidden on smaller tiles to avoid clutter and ensure the tile boundaries are respected.
*   **Timezone-Aware:** Event times are displayed accurately in the user's local timezone.
*   **Stable Persistence:** Your schedule is reliably saved and restored between sessions on a per-day basis.
*   **Input Validation:** The app prevents the creation of events with a zero or negative duration.

## Changelog

*   **August 7, 2025:**
    *   Overhauled the day navigation with a seamless, animated swipe gesture using `TabView`. This resolves gesture conflicts and improves the user experience.
    *   Changed the "Travel" event category color to a custom rust color for better visibility and contrast in both light and dark modes.
    *   Improved text rendering on small event tiles to prevent overflow. Tiles for events under 30 minutes no longer display text, and tiles for events between 30 and 60 minutes have smaller padding.
*   **August 5, 2025:**
    *   Fixed a build failure caused by several SwiftUI compilation errors.
    *   Made the `RepeatOption` enum `Hashable` to allow its use in `Picker` views.
    *   Corrected closure calls in `ContentView` to prevent crashes when creating or editing an event.
    *   Refactored `EditEventView` to prevent compiler timeouts.
    *   Updated deprecated `onChange` modifier.
    *   Fixed a crash when deleting a repeating event by safely unwrapping the event's `seriesId`.
    *   Refactored event saving logic to correctly handle both single-day and repeating events.
    *   Added a slide animation to the day-swipe gesture for a more intuitive user experience.
    *   Resolved a build failure by moving data persistence functions to their correct scope.
    *   Removed the visible drag handles from event tiles for a cleaner aesthetic.
    *   Fixed a bug where repeating events created for a future date would not be saved correctly.
    *   Fixed event deletion and implemented a conditional alert for repeating events.
    *   Users can now drag the body of an event tile to reschedule it.
    *   Improved gesture handling to prevent conflicts between dragging and long-pressing.
    *   Fixed a bug that prevented single instances of repeating events from being deleted correctly.
    *   Reverted the time entry system to use time wheels instead of text fields.
    *   Replaced the red box around the current date with a more subtle red dot indicator.
    *   Fixed a bug that prevented events from being created on dates other than the currently selected date.
    *   Fixed a bug where events created on a different day would be displayed at the wrong time.
    *   Fixed an issue where event tiles for short events would overflow their boundaries.
    *   Event tiles now show the updated time in real-time as they are being dragged.
    *   Time labels in the main schedule view are now perfectly centered on their corresponding hour lines.
    *   Improved gesture handling to correctly differentiate between scrolling and dragging events.

## Getting Started

To get started with this project, you'll need to have [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed. You can install it with Homebrew:

```bash
brew install xcodegen
```

Once you have XcodeGen installed, you can generate the Xcode project:

```bash
xcodegen generate
```

Now, you can open the `Become.xcodeproj` file in Xcode and run the app.

## Key Technologies

*   **SwiftUI:** The app is built entirely with SwiftUI.
*   **UserDefaults:** Event data is persisted using `UserDefaults`.
*   **XcodeGen:** We use XcodeGen to manage the Xcode project. The project's structure and build settings are defined in the `project.yml` file. **Please do not edit the `.xcodeproj` file directly.**
*   **Codemagic:** The `codemagic.yaml` file defines our CI/CD pipeline. It automates the process of building, signing, and deploying the app to App Store Connect.

## Project Structure

*   `Become/`: This directory contains all the source code for the app.
*   `Become/Assets.xcassets/`: This is where you'll find all the assets for the app, including the app icons.
*   `project.yml`: This file defines the project's structure and build settings.
*   `codemagic.yaml`: This file defines the CI/CD pipeline.

## Deployment

This project is set up for automated deployments with Codemagic. To deploy a new version of the app, simply push your changes to the `main` branch. This will trigger a new build in Codemagic, which will automatically deploy the app to App Store Connect.