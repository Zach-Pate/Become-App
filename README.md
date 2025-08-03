> **Note:** These files build perfectly. Please be very sparing in editing files to ensure that the build continues to work.

# Become - A Daily Planner App

This is a SwiftUI app that helps you plan your day. It features a vertical timeline where you can schedule and rearrange events.

## Features

*   **24-Hour Scrollable Timeline:** The main view is a vertical timeline that displays your full day's schedule.
*   **Intuitive Gestures:**
    *   Drag the body of an event to move it.
    *   Drag the top or bottom handles to resize it.
*   **Proportional Resizing:** The event duration changes in direct proportion to how far you drag the resize handles.
*   **Snapping:** Events snap to 15-minute increments for easy alignment.
*   **Haptic Feedback:** The app provides haptic feedback when you're moving or resizing an event.
*   **Dynamic Tile Sizing:** Event tiles are sized proportionately to their duration.
*   **Adaptive Tile Content:** The event title is hidden on smaller tiles to avoid clutter.
*   **Timezone-Aware:** Event times are displayed accurately in the user's local timezone.
*   **Stable Persistence:** Your schedule is reliably saved and restored between sessions.

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