# Nabeh & Julia — Paint Arena (Flutter prototype)

A portrait-oriented Flutter prototype for Android.

## Included
- Animated night-sky universe with drifting stars, moon and heart constellations
- Floating, perspective-styled 3D-look typography for Nabeh & Julia
- Five selectable paint colors
- Tap-to-shoot paint splashes and heart impact bursts
- Progress meter and romantic victory screen
- Restart / replay

## Build an APK
You need Flutter SDK (stable channel), Android Studio / Android SDK, and Java 17.

1. Unzip this project.
2. Open a terminal in the project folder.
3. Run:
   ```bash
   flutter pub get
   flutter create . --platforms=android
   flutter build apk --release
   ```
4. APK output:
   `build/app/outputs/flutter-apk/app-release.apk`

The current execution environment does not include the Flutter SDK, so this source prototype is provided but an APK has not been compiled here. The visual lettering is a Flutter-rendered 2.5D effect; full mesh-based 3D and physically layered paint would be a later Unity/3D-engine upgrade.
