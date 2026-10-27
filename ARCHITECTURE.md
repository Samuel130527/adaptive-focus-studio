# Adaptive Focus Studio — Architecture

## 1. Overview
Adaptive Focus Studio is a Flutter application for managing focus sessions, focus presets, session history, and daily focus goals.

## 2. Main Components

### Presentation Layer
Flutter screens and widgets display focus controls, presets, history, progress, and settings.

### State Management
Document the Riverpod providers and state-management responsibilities used by the application.

### Recommendation Logic
The Smart Focus recommendation logic is located in:
`lib/utils/focus_recommendation.dart`

### Local Persistence
- SQLite: document the actual tables, fields, and CRUD operations implemented.
- SharedPreferences: document the settings actually persisted by the app.

## 3. Data Flow
1. The user interacts with a screen.
2. The relevant application state or provider processes the action.
3. Data is read from or written to local storage when needed.
4. Updated state is reflected in the user interface.
5. The recommendation feature uses its implemented inputs and rules to suggest a focus duration.

Verify this flow against the actual implementation.

## 4. Offline Design
Describe which features work without an internet connection and verify this on a device or emulator.

## 5. Error Handling
Document how the app handles invalid inputs, storage failures, missing data, and other relevant errors.

## 6. Testing
List the actual unit, widget, and integration tests in the `test/` directory. Include test results from the final version.

## 7. Known Limitations
Record genuine limitations discovered during testing, including any recommendation or persistence edge cases.
