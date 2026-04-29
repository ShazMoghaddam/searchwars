# SearchWars — First-Time Setup

After cloning from GitHub, run **one command** before opening in your IDE or building:

```bash
cd searchwars
flutter pub get
```

This does three things automatically:
1. Downloads all Dart/Flutter package dependencies
2. Generates `android/gradle/wrapper/gradle-wrapper.jar` (the Android build tool)
3. Regenerates `.flutter-plugins` and `.dart_tool/` (excluded from git intentionally)

---

## Building for Android (Play Store)

```bash
# Create your keystore (first time only)
keytool -genkey -v -keystore ~/searchwars-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias searchwars

# Create android/key.properties (never commit this file)
echo "storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=searchwars
storeFile=/Users/YOU/searchwars-keystore.jks" > android/key.properties

# Build the release bundle
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

Upload `app-release.aab` to the Google Play Console.

---

## Firebase Security Rules

Paste the contents of `firebase_rules.json` into:
**Firebase Console → Realtime Database → Rules**

---

## Running the Gradle icon generator (optional)

If you want to regenerate launcher icons after swapping `assets/icons/app_icon.png`:

```bash
flutter pub run flutter_launcher_icons
```
