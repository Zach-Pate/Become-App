> **Note:** These files build perfectly. Please be very sparing in editing files to ensure that the build continues to work.

# Become

This is a simple "Hello, World!" SwiftUI app for iOS.

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

*   **XcodeGen:** We use XcodeGen to manage the Xcode project. The project's structure and build settings are defined in the `project.yml` file. **Please do not edit the `.xcodeproj` file directly.**
*   **Codemagic:** The `codemagic.yaml` file defines our CI/CD pipeline. It automates the process of building, signing, and deploying the app to App Store Connect.

## Project Structure

*   `Become/`: This directory contains all the source code for the app.
*   `Become/Assets.xcassets/`: This is where you'll find all the assets for the app, including the app icons.
*   `project.yml`: This file defines the project's structure and build settings.
*   `codemagic.yaml`: This file defines the CI/CD pipeline.

## Deployment

This project is set up for automated deployments with Codemagic. To deploy a new version of the app, simply push your changes to the `main` branch. This will trigger a new build in Codemagic, which will automatically deploy the app to App Store Connect.