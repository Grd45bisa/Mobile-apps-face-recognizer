# CLAUDE.md – Persistent context for Claude Code

## Project Overview
Presensia – Flutter mobile app for face‑based attendance, worklog, calendar, and performance reporting.
Backend: Supabase (PostgreSQL + Auth). Face detection: Google ML Kit. Recognition: MobileFaceNet/TFLite (assets/models/mobilefacenet.tflite).

## Tech Stack
- Flutter 3.19+, Dart 3.3
- State Management: Provider (or Riverpod – follow existing usage)
- UI: Material Design
- Local DB: SQLite via sqflite
- Cloud: Supabase (realtime, storage)
- ML: google_mlkit_face_detection, tflite_flutter
- Image processing: image package
- Calendar: table_calendar
- Charts: fl_chart
- PDF: pdf + printing
- Notifications: flutter_local_notifications, timezone

## Coding Standards
- Follow Flutter lint set (analysis_options.yaml – already configured).
- Format with `dart format .` before commit.
- Use `// TODO:` for technical debt, `// FIXME:` for bugs.
- Name classes, methods, variables in `UpperCamelCase` / `lowerCamelCase` as per Dart style.
- Prefer `const` constructors where possible.
- Avoid `dynamic` unless necessary; specify types.
- Keep widget build methods short; extract sub‑widgets.

## Build & Run Commands
- `flutter pub get` – install dependencies.
- `flutter run` – debug on attached device/emulator.
- `flutter build apk --release` – produce release APK.
- `flutter test` – run unit/widget tests.
- `flutter pub outdated` – check for updates.
- `flutter pub upgrade --major-versions` – upgrade major versions (review breaking changes).

## Architecture Overview
```
lib/
  features/
    attendance/   # UI, camera, face recognition pipeline
    auth/         # login, register, password reset
    calendar/     # calendar view, worklog per day
    enrollment/   # face enrollment (1‑photo flow)
    home/         # dashboard
    main_nav/     # bottom navigation
    profile/      # user data, face status
    report/       # PDF report generation
    tracker/      # project & worklog tracking
  shared/
    services/     # Supabase client, attendance, face recognition, embedding sync, notifications
    database/     # SQLite helpers (embedding cache)
    models/       # data classes (User, Worklog, Project, etc.)
    providers/    # state management (if using Provider)
    theme/        # colors, typography
  main.dart
assets/
  models/
    mobilefacenet.tflite
    sface.tflite   # alternative, higher‑accuracy model
supabase/
  schema.sql       # tables: profiles, face_embeddings, attendance, worklog, projects, etc.
```

### Face Recognition Pipeline (core)
1. **Detection** – ML Kit `FaceDetector` → `Face` (bounding box + landmarks).
2. **Alignment** – eye‑anchor rotation (if landmarks available) → fallback to padded bbox.
3. **Crop & Resize** → 112×112 RGB.
4. **Normalization** → pixel values to `[-1, 1]` (matches MobileFaceNet input).
5. **Inference** – TFLite interpreter → 192‑dim L2‑normalized embedding.
6. **Matching** – cosine similarity against stored embeddings (threshold ≈ 0.80).
   - Euclidean distance used only for debugging; prefer cosine for lighting invariance.
7. **Verification** – require ≥ 2 of 3 consecutive frames to succeed (reduces transient blur).

## Accuracy‑Improvement Guidelines (advisory)
- **Model:** Prefer `sface.tflite` (higher accuracy) if latency permits; benchmark on target device.
- **Enrollment:** Capture 3–5 poses (frontal, ±15° yaw, neutral/smile) and store all embeddings per user.
- **Threshold:** Tune cosine similarity threshold on a validation set; start at 0.80.
- **Pre‑filter:** Reject frames if:
  - Blur (Laplacian variance < 100).
  - Brightness outside 50‑200 on face crop.
  - Face size < 15% of frame height.
  - Yaw/Pitch > 20° or Roll > 15° (using MLKit landmarks).
- **Liveness (optional):** Simple eye‑blink detection (2 blinks) or head‑pose challenge.
- **Database:** Store each embedding as JSON array in Supabase `face_embeddings`; retrieve all for a user at verification.
- **Re‑enrollment:** Prompt user to renew face data every 90 days or when similarity drift > 0.1 observed.

## Workflow & Git
- **Requirement:** Always read `CLAUDE.md` and project context before starting any implementation.
- **Requirement:** After completing a task, record/log what has been done to maintain progress continuity.
- Branch naming: `feature/<short-description>`, `bugfix/<issue>`, `release/vX.Y`.
- Commit messages: Conventional style: `feat: add X`, `fix: resolve Y`, `refactor: simplify Z`.
- Pull‑request template: include summary, testing steps, screenshots if UI.
- Run `flutter test` and `flutter analyze` on CI before merge.
- Tag releases with `vX.Y.Z` and create GitHub release.

## Environment Setup (for new developers)
1. Install Flutter SDK (≥ 3.19) and Dart.
2. Run `flutter pub get`.
3. Ensure Android device or emulator with API 21+ (camera & ML Kit require real device for best results).
4. Create Supabase project, run `supabase/schema.sql` to set up tables.
5. Copy Supabase URL & anon key to `lib/shared/services/supabase_client.dart` (or env vars).
6. Place TFLite models in `assets/models/` and verify they are listed in `pubspec.yaml` under `flutter assets`.
7. Run `flutter run` to verify app launches.

## Testing
- Unit tests: `test/` – focus on services, models, face recognition logic.
- Widget tests: verify UI states (loading, success, error).
- Integration test (optional): use `integration_test` for end‑to‑end enrollment → attendance flow.
- Aim for ≥ 80% code coverage on services and models.

## Imports (optional)
You may split detailed rules into separate files and reference them here:
```
@import ./rules/build_commands.md
@import ./rules/coding_standards.md
@import ./rules/face_recognition.md
```
Create the files under `.claude/rules/` or keep them alongside this CLAUDE.md.

---
*Remember: CLAUDE.md is advisory. Claude will try to follow it but may ignore irrelevant or conflicting instructions. Keep it concise (< 200 lines) and focused on what truly matters for this project.*