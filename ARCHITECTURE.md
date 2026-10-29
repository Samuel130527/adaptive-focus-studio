# Adaptive Focus Studio — Architecture

## 1. Overview

Adaptive Focus Studio is a Flutter application that helps students manage focus sessions, create personalized focus presets, review session history, and monitor daily and weekly study progress.

The application uses local persistence to retain focus data and settings on the device. Its smart focus helper uses local recommendation logic rather than a cloud-based AI service.

## 2. Architecture and Main Components

### 2.1 Presentation Layer

The presentation layer consists of Flutter screens and widgets that display the timer, focus presets, session history, progress chart, and settings.

Responsibilities include:
- Displaying application data.
- Accepting user input.
- Validating form values and showing feedback.
- Responding to user actions such as starting a timer, editing a preset, or applying a recommendation.

### 2.2 State Management

Riverpod manages application state through providers.

Document the actual providers responsible for:
- Focus presets.
- Focus sessions and history.
- Timer state.
- Settings and theme preferences.
- Smart focus recommendations.

State ownership, loading states, error handling, and provider disposal should be described using the actual implementation.

### 2.3 Domain and Recommendation Logic

The smart focus recommendation logic is located in:

`lib/utils/focus_recommendation.dart`

This component separates recommendation calculations from the screen layout.

Document the actual inputs, rules, output units, fallback behavior when there is no completed session history, and how users can apply or dismiss a suggestion.

The helper should be described accurately as rule-based or statistical if that is what the code implements; do not describe it as a trained machine-learning model unless one is actually used.

### 2.4 Data and Persistence Layer

**SQLite**

SQLite stores structured local application data, including focus presets and focus sessions, according to the implemented schema.

**SharedPreferences**

SharedPreferences stores simple application preferences, such as the default focus duration, daily focus goal, and notification preference, if those keys are implemented.

Document the actual keys, default values, and behavior when the application restarts.

### 2.5 Dependency Injection and Repository Boundaries

Describe how providers obtain their dependencies and how database access is separated from UI code.

If the application uses repository classes, document their interfaces and responsibilities. If a repository pattern or explicit dependency injection is not implemented, state that limitation rather than claiming the pattern is present.

## 3. Data Flow

The intended application flow is:

1. The user interacts with a Flutter screen.
2. The screen invokes the relevant provider or application logic.
3. The logic validates the input and reads or updates local data when required.
4. The provider exposes the updated state.
5. The interface refreshes to reflect the current data.
6. The recommendation helper evaluates its implemented inputs and rules to produce a suggestion.
7. The user can review the suggestion and choose whether to apply or dismiss it.

Verify each step against the actual code and document any exceptions.

## 4. Offline Design

The application is designed to keep focus presets, session history, and supported settings on the device.

Verify offline operation by:
- Launching the app without an internet connection.
- Creating or updating local data.
- Restarting the application.
- Confirming that persisted data remains available.

Record the device or emulator used and the actual result. Do not claim offline verification until the test has been performed.

## 5. Error Handling and Lifecycle

Document how the application handles:
- Invalid or out-of-range focus durations.
- Empty or missing session history.
- Database read/write failures.
- Missing or invalid preset data.
- Timer completion, cancellation, and reset.
- Widget disposal and timer/resource cleanup.

Describe the actual user feedback and recovery behavior for each relevant case.

## 6. Testing and Evaluation

Analyzing adaptive_focus_studio...                                      .
No issues found! (ran in 3.2s) more information.
PS C:\Users\s\Desktop\inc1\adaptive_focus_studio> flutter test   
00:05 +6: All tests passed!                    

## 7. Known Limitations and Design Trade-offs

Document genuine limitations found during implementation and testing, such as:
- Recommendation quality when little or no session history is available.
- Any unsupported database operations.
- Missing error recovery or lifecycle tests.
- Architecture responsibilities that remain coupled.

Explain the trade-offs made, the alternative considered, and what you would improve next.

## 8. Architecture Summary

The application separates its user interface, state management, recommendation logic, and local persistence to support maintainability and offline use.

The final architecture description must reflect the code that actually exists in the repository, including any patterns or testing layers that have not yet been implemented.
