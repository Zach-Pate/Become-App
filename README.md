# Become

This is a "Hello, World!" SwiftUI application for iOS. This document provides a comprehensive overview of the project's setup, the challenges that were overcome to achieve a successful build, and the processes that should be followed to ensure its continued success.

## Project Overview

This project is a simple SwiftUI application that displays "Hello, world!" on the screen. It is configured for automated builds and deployments using Codemagic, and the project structure is managed by `xcodegen`.

## Build Process

The project is built using the following key tools:

*   **XcodeGen:** The Xcode project is generated from the `project.yml` file. This is the single source of truth for the project's structure and build settings. **Do not edit the `.xcodeproj` file directly.** All changes to the project's configuration should be made in the `project.yml` file.
*   **Codemagic:** The `codemagic.yaml` file defines the CI/CD pipeline for this project. It automates the process of building, signing, and deploying the app to App Store Connect.
*   **Fastlane:** While not directly used in the `codemagic.yaml`, the `deploy.sh` script provides a manual deployment option that uses Fastlane for code signing and deployment.

## Resolved Issues

The following issues were resolved to achieve a successful build and deployment:

1.  **Missing App Entry Point:** The initial build failed because the app was missing a main entry point. This was resolved by creating the `Become/BecomeApp.swift` file with the `@main` attribute.
2.  **Missing Version Numbers:** The app failed to upload to App Store Connect because the `Info.plist` was missing the `CFBundleVersion` and `CFBundleShortVersionString` keys. This was resolved by adding the `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` settings to the `project.yml` file.
3.  **Missing App Icons:** The app failed to upload to App Store Connect because it was missing the required app icons. This was resolved by creating an `AppIcon.appiconset` in the `Assets.xcassets` directory and populating it with the required icon sizes.
4.  **Missing Launch Screen:** The app failed to upload to App Store Connect because it was missing a launch screen. This was resolved by updating the `Info.plist` to use a modern, programmatic launch screen configuration.
5.  **`Info.plist` Generation Issues:** The initial attempts to fix the `Info.plist` issues by adding settings to the `project.yml` file were unsuccessful because `xcodegen` was not generating the `Info.plist` correctly. This was resolved by creating a dedicated `Info.plist` file and referencing it in the `project.yml`.

## Processes for Success

To ensure the continued success of this project, please follow these processes:

*   **Project Configuration:** All changes to the project's structure, build settings, or dependencies should be made in the `project.yml` file. After making changes to the `project.yml` file, you will need to run `xcodegen generate` to update the Xcode project.
*   **App Versioning:** To update the app's version, you will need to update the `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` settings in the `project.yml` file.
*   **App Icons:** All app icons are managed in the `src/Become/Assets.xcassets/AppIcon.appiconset` directory. If you need to update the app icons, you will need to replace the existing image files with new ones of the correct size.
*   **Dependencies:** This project does not currently have any dependencies. If you need to add dependencies, you should use the Swift Package Manager and add them to the `project.yml` file.
*   **Deployment:** The app is configured for automated deployment with Codemagic. To deploy a new version of the app, you will need to push your changes to the `master` branch of the GitHub repository. This will trigger a new build in Codemagic, which will automatically deploy the app to App Store Connect.

By following these processes, you can help to ensure that this project remains in a healthy and deployable state.
