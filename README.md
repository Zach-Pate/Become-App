> **Note:** These files build perfectly. Please be very sparing in editing files to ensure that the build continues to work.

# Become - A Daily Planner App

This is a SwiftUI app that helps you plan your day. It features a vertical timeline where you can schedule and rearrange events.

## Features

*   **Date Selection:** A horizontal menu at the top of the screen allows you to select different days. The app automatically starts on the current date and highlights it in the menu.
*   **Aesthetic Pop-ups:** The "Add New Event" and "Edit Event" pop-ups are styled to be more visually appealing and no longer take up the entire screen.
*   **Add New Events:** A "+" button on the date selector bar opens a pop-up where you can create new events with a title, start time, end time, and category.
*   **Edit and Delete Events:** Long-press on an event to open a pop-up where you can edit its details or delete it.
*   **Event Categories:** Events can be assigned to categories, each with a unique color. The category picker now includes a colored circle next to each category name.
    *   Meeting (Blue)
    *   Meal (Orange)
    *   Exercise (Green)
    *   Work (Indigo)
    *   Personal (Purple)
    *   Family (Pink)
    *   Social (Teal)
    *   Errands (Yellow)
    *   Appointment (Red)
    *   Travel (Cyan)
    *   Rest (Mint)
    *   Other (Gray)
*   **24-Hour Scrollable Timeline:** The main view is a vertical timeline that displays your full day's schedule.
*   **Visual Snap Grid:** A faint grid of 5-minute increments provides a visual guide for event placement.
*   **Live Time Indicator:** A horizontal bar, anchored to the left edge of the screen, shows the current time and updates every minute. The indicator has been styled for better visibility.
*   **Intuitive, Real-Time Gestures:**
    *   Drag the body of an event to move it.
    *   Drag the top or bottom edge of an event to resize it in real-time.
    *   Long-press an event to edit or delete it.
*   **Smooth Dragging:** Events now move and resize smoothly with your finger, without any jitter. The time display on the tile also updates in real-time.
*   **Velocity-Based Snapping:**
    *   Drag slowly for precise, 1-minute adjustments.
    *   Drag quickly to snap to 5-minute increments.
*   **Haptic Feedback:** The app provides haptic feedback when you're moving or resizing an event.
*   **Dynamic Tile Sizing:** Event tiles are sized proportionately to their duration.
*   **Adaptive Tile Content:** The event title and time are hidden on smaller tiles to avoid clutter.
*   **Timezone-Aware:** Event times are displayed accurately in the user's local timezone.
*   **Stable Persistence:** Your schedule is reliably saved and restored between sessions on a per-day basis.

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