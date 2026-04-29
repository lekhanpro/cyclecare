# GitHub Actions Workflows for CycleCare Flutter

## Overview

This document describes the CI/CD workflows set up for the CycleCare Flutter app.

## Workflows

### 1. Flutter CI (`flutter-ci.yml`)

**Purpose**: Quick validation on every push and pull request

**Triggers**:
- Push to `flutter-migration` branch
- Pull requests to `flutter-migration` or `main` branch
- Only when files in `cyclecare_flutter/` change

**Jobs**:

#### Analyze & Test
- Checkout code
- Setup Flutter 3.16.0
- Get dependencies
- Verify code formatting
- Run static analysis
- Run unit tests
- Upload coverage to Codecov

#### Build APK
- Build debug APK
- Upload as artifact (7 days retention)

**Artifacts**:
- `cyclecare-flutter-apk` - Debug APK for testing

---

### 2. Flutter Build (`flutter-build.yml`)

**Purpose**: Comprehensive builds for all platforms

**Triggers**:
- Push to `flutter-migration` or `main` branch
- Pull requests
- Manual workflow dispatch
- Only when files in `cyclecare_flutter/` change

**Jobs**:

#### Build Android
- Setup Java 17 and Flutter
- Run code generation (Drift, Freezed, Riverpod)
- Analyze code
- Run tests
- Build debug and release APKs
- Upload both APKs as artifacts

**Artifacts**:
- `cyclecare-flutter-debug-apk` (30 days)
- `cyclecare-flutter-release-apk` (90 days)

#### Build iOS
- Setup Flutter on macOS
- Run code generation
- Build iOS app (no codesign)
- Create archive
- Upload as artifact

**Artifacts**:
- `cyclecare-flutter-ios-build` (30 days)

#### Build Web
- Setup Flutter
- Run code generation
- Build web version
- Upload as artifact

**Artifacts**:
- `cyclecare-flutter-web` (30 days)

#### Create Release
- Triggers only on tags matching `flutter-v*`
- Downloads all platform artifacts
- Creates GitHub Release with:
  - Android APK
  - iOS archive
  - Web build
  - Release notes

---

## How to Use

### Running Workflows Manually

1. Go to **Actions** tab in GitHub
2. Select **Flutter Build** workflow
3. Click **Run workflow**
4. Choose branch and click **Run workflow**

### Downloading Build Artifacts

1. Go to **Actions** tab
2. Click on a completed workflow run
3. Scroll to **Artifacts** section
4. Download desired artifact

### Creating a Release

1. Create and push a tag:
   ```bash
   git tag flutter-v1.0.0
   git push origin flutter-v1.0.0
   ```

2. Workflow automatically:
   - Builds all platforms
   - Creates GitHub Release
   - Attaches all artifacts

### Local Development

Before pushing, ensure your code passes CI checks:

```bash
cd cyclecare_flutter

# Format code
dart format .

# Analyze
flutter analyze

# Run tests
flutter test

# Build
flutter build apk --debug
```

## Workflow Status Badges

Add these to your README:

```markdown
[![Flutter CI](https://github.com/lekhanpro/cyclecare/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/flutter-ci.yml)

[![Flutter Build](https://github.com/lekhanpro/cyclecare/actions/workflows/flutter-build.yml/badge.svg)](https://github.com/lekhanpro/cyclecare/actions/workflows/flutter-build.yml)
```

## Artifact Retention

| Artifact | Retention | Purpose |
|----------|-----------|---------|
| Debug APK (CI) | 7 days | Quick testing |
| Debug APK (Build) | 30 days | Development testing |
| Release APK | 90 days | Production builds |
| iOS Build | 30 days | Development/testing |
| Web Build | 30 days | Web deployment |

## Environment Requirements

### Android Build
- Ubuntu latest
- Java 17 (Zulu distribution)
- Flutter 3.16.0

### iOS Build
- macOS latest
- Flutter 3.16.0
- Xcode (latest)

### Web Build
- Ubuntu latest
- Flutter 3.16.0

## Secrets Required

Currently no secrets are required. For future enhancements:

- `ANDROID_KEYSTORE`: For signed releases
- `ANDROID_KEY_PROPERTIES`: Keystore properties
- `APPLE_CERTIFICATE`: For iOS signing
- `CODECOV_TOKEN`: For coverage reports (optional)

## Troubleshooting

### Build Fails on Code Generation

If `build_runner` fails:
1. Check that all dependencies are in `pubspec.yaml`
2. Ensure generated files are in `.gitignore`
3. Run locally: `flutter pub run build_runner build --delete-conflicting-outputs`

### iOS Build Fails

Common issues:
- CocoaPods version mismatch
- Missing iOS dependencies
- Xcode version incompatibility

Solution: Update Flutter and dependencies

### Web Build Fails

Common issues:
- Missing web dependencies
- Incompatible packages

Solution: Check package compatibility with web platform

## Performance Optimization

### Caching

Workflows use caching for:
- Flutter SDK
- Pub dependencies
- Gradle dependencies (Android)
- CocoaPods (iOS)

### Parallel Jobs

Jobs run in parallel when possible:
- Android, iOS, and Web builds run simultaneously
- Reduces total workflow time

## Future Enhancements

1. **Automated Testing**
   - Integration tests
   - Screenshot tests
   - Performance tests

2. **Code Quality**
   - SonarQube integration
   - Dependency vulnerability scanning
   - License compliance checking

3. **Deployment**
   - Automatic deployment to Play Store
   - TestFlight distribution
   - Web hosting deployment

4. **Notifications**
   - Slack/Discord notifications
   - Email on build failures
   - Status updates

## Contributing

When adding new workflows:
1. Test locally first
2. Use workflow dispatch for testing
3. Document in this file
4. Add status badges to README

## Support

For workflow issues:
1. Check workflow logs in Actions tab
2. Review this documentation
3. Open an issue with workflow run link

---

**Last Updated**: 2024
**Maintained By**: Lekhan HR, Mithun Gowda B
