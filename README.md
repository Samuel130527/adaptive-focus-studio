# Adaptive Focus Studio

A Flutter-based productivity application designed to help students organize focus sessions, manage study time, and track their progress.

## Features

- **Focus Timer:** Start, pause, resume, finish, and reset focus sessions.
- **Custom Focus Presets:** Create, edit, and delete presets with personalized durations and categories.
- **Session History:** View completed sessions, early finishes, and recorded focus time.
- **Daily Focus Goals:** Set daily targets and monitor progress.
- **Weekly Progress Chart:** Review focus time recorded over the last seven days.
- **Smart Focus Suggestions:** Receive suggested session durations based on previous completed sessions.
- **Dark Mode:** Switch between light and dark themes.
- **Persistent Settings:** Save preferences locally on the device.
- **Local Data Storage:** Store focus presets and session history locally.

## Built With

- Flutter
- Dart
- Riverpod
- SQLite
- SharedPreferences
- Material Design 3

## Getting Started

### Prerequisites

Install the following tools:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Git](https://git-scm.com/downloads)
- Android Studio or Visual Studio Code
- An Android emulator or a connected Android device

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/Samuel130527/adaptive-focus-studio.git
   ```

2. Open the project directory:

   ```bash
   cd adaptive-focus-studio
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## Run Tests

Run the static analyzer:

```bash
flutter analyze
```

Run the automated tests:

```bash
flutter test
```

## Build an Android APK

To build a release APK, run:

```bash
flutter build apk --release
```

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project Structure

```text
lib/
├── main.dart
├── models/
├── providers/
├── screens/
├── utils/
└── theme_controller.dart

test/
```

- `main.dart` — Application entry point and primary screens.
- `models/` — Data models for focus presets and sessions.
- `providers/` — State management and data providers.
- `screens/` — Application screens, including settings.
- `utils/` — Focus recommendation logic.
- `theme_controller.dart` — Theme preference and light/dark mode management.
- `test/` — Automated tests.

## Usage

1. Open the app and select a focus preset.
2. Start a focus session and manage the timer.
3. Finish a session to save it to your history.
4. Set your daily focus goal in Settings.
5. Review your weekly progress and smart focus suggestions.
6. Enable dark mode from Settings if preferred.

## Repository

GitHub: https://github.com/Samuel130527/adaptive-focus-studio

## License

Add a license file if you intend to distribute this project under an open-source license.
