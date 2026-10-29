# Adaptive Focus Studio

Adaptive Focus Studio is a Flutter-based productivity application designed to help students organize focus sessions, manage study time, and track their progress.

## Features

- **Focus Timer:** Start, pause, resume, finish, and reset focus sessions.
- **Custom Focus Presets:** Create, edit, and delete presets with personalized durations and categories.
- **Session History:** View recorded focus sessions, including early finishes.
- **Daily Focus Goals:** Set daily targets and monitor progress.
- **Weekly Progress Chart:** Review focus time recorded over the last seven days.
- **Smart Focus Suggestions:** Receive suggested focus durations using local recommendation logic and available session history.
- **Dark Mode:** Switch between light and dark themes.
- **Persistent Settings:** Save preferences locally on the device.
- **Local Data Storage:** Store focus presets and session history using SQLite and SharedPreferences.

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

## Testing

Run the static analyzer:

```bash
flutter analyze
```

Run the automated tests:

```bash
flutter test
```

Record the actual results of these commands when preparing the final submission.

## Build an Android APK

Build the release APK using:

```bash
flutter build apk --release
```

The generated APK should be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Test the release APK on a compatible Android device or emulator before submitting it.

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

- `main.dart` — Application entry point.
- `models/` — Data models for focus presets and sessions.
- `providers/` — State management and data providers.
- `screens/` — Application screens, including settings.
- `utils/` — Utility logic, including focus recommendations.
- `theme_controller.dart` — Theme preference and light/dark mode management.
- `test/` — Automated tests.

## Usage

1. Open the application and select a focus preset.
2. Start a focus session and control the timer.
3. Finish a session to record it in session history.
4. Configure your daily focus goal in Settings.
5. Review weekly progress and available focus suggestions.
6. Switch to dark mode from Settings if preferred.

## Project Management and Contribution Evidence

**ClickUp Kanban Board:**  
https://app.clickup.com/90141806593/v/b/2kydxm01-334

**Contribution Evidence PDF:**  
`Kanban_Contribution_Evidence.pdf`

The evidence document should include genuine board snapshots, task activity, code or commit references, test/review results, and workflow reflection as required by the course.

## Known Limitations

- Smart focus recommendations depend on the implemented local recommendation logic and the session data available on the device.
- Verify create, read, update, and delete support for both required database entities before claiming full CRUD compliance.
- Document any remaining test failures, unsupported behaviors, or other limitations identified during final testing.

## Repository

GitHub: https://github.com/Samuel130527/adaptive-focus-studio

## License

No open-source license is specified in this README. Add a license file only if you intend to distribute the project under a particular license.
