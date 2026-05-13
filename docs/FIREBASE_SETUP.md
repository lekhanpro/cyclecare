# Firebase Setup Guide

Firebase is optional — the app works fully without it. Firebase adds:
- Google Sign-In
- Push notifications (FCM)
- Cloud sync (alternative to Supabase)

## 1. Create Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project: **CycleCare**
3. Add an Android app with package name: `com.lekhanpro.cyclecare`
4. Download `google-services.json` → place in `android/app/`

## 2. Run FlutterFire configure

FlutterFire CLI is already installed at:
`C:\Users\lekhan hr\AppData\Local\Pub\Cache\bin\flutterfire.bat`

```bash
flutterfire configure --project=your-firebase-project-id
```

This generates `lib/firebase_options.dart` automatically.

## 3. Enable Firebase packages

In `pubspec.yaml`, uncomment:
```yaml
firebase_core: ^3.8.1
firebase_auth: ^5.4.1
firebase_messaging: ^15.1.5
google_sign_in: ^6.2.2
```

In `android/app/build.gradle`, uncomment:
```groovy
id "com.google.gms.google-services"
```
and:
```groovy
implementation platform('com.google.firebase:firebase-bom:33.7.0')
implementation 'com.google.firebase:firebase-analytics'
```

In `android/build.gradle`, uncomment:
```groovy
classpath 'com.google.gms:google-services:4.4.2'
```

## 4. Enable Auth providers

In Firebase Console → Authentication → Sign-in method:
- Enable **Email/Password**
- Enable **Google** (add SHA-1 fingerprint from your keystore)

Get SHA-1:
```bash
D:\tools\java17\bin\keytool.exe -list -v -keystore android/app/cyclecare-release.jks -alias cyclecare -storepass "CycleCare2024!"
```

## 5. Enable FCM

In Firebase Console → Project Settings → Cloud Messaging:
- Copy the **Server key** → set as Supabase secret: `supabase secrets set FCM_SERVER_KEY=...`

## 6. Update main.dart

Uncomment Firebase initialization in `lib/main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```
