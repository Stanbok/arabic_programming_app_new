# Python Learning App (Flutter)

This is a skeleton project for a modern Android educational application designed to teach Python, following UX principles from Duolingo, Sololearn, and Mimo. It uses Flutter with a clean architecture and JSON-driven content.

## Getting Started

1. **Install Flutter SDK** (latest stable) and ensure `flutter` is on your PATH.
2. Navigate to the project folder:
   ```bash
   cd "d:\Craak\Games\learn python app\python_learning_app"
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. **Generate model code** (required for Freezed models):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
5. Run the app on an emulator or device:
   ```bash
   flutter run
   ```
6. For release builds:
   ```bash
   flutter build apk --release
   ```

## Structure

- `lib/core`: shared models, services, theme.
- `lib/features`: feature modules (home, unit, lesson, quiz, gamification).
- `assets/content`: JSON files driving units/lessons/quizzes.

## Notes

- State management uses Riverpod; you can switch to Bloc if preferred.
- Routing is handled by `go_router`.
- Models generated via `freezed`+`json_serializable` (`flutter pub run build_runner build`).
- Use the `content_service` and Riverpod providers to load units, lessons, and quizzes from JSON assets.
- Gamification state (XP, streak, badges) and progress tracking are implemented via `StateNotifier` providers.

The markdown specification file in the root (`Build a modern Android educational app.md`) contains detailed UX and technical requirements.
