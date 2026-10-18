# Family Essentials — mobile app

Flutter, Clean Architecture per feature, `bloc` for state, GoRouter for
navigation, `get_it` for injection, `dio` for HTTP. Warm Sage for the look.

## Requirements

- Flutter 3.x with the Dart SDK it ships
- The API running (see `../Backend/README.md`)

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/mobile
```

`10.0.2.2` is the host machine as seen from an Android emulator. The default in
`lib/core/config/app_config.dart` is that value, so a plain `flutter run` works on
an emulator; on a physical device pass your machine's LAN address.

**The base URL already ends in `/mobile`,** so every endpoint is written
`/v1/...` — never `/mobile/v1/...`.

## Structure

Feature slices, each with the same four layers and no code generation (no
`freezed`, no `build_runner`, no `.g.dart` — everything is hand-written):

```
lib/
├── core/
│   ├── config/        app_config — the API base URL
│   ├── di/            injector — every registration lives here
│   ├── error/         AuthFailure, AppFailure
│   ├── network/       DioClient — base URL, timeouts, bearer interceptor
│   ├── router/        app_router (GoRouter) + main_shell (the tab bar)
│   ├── session/       AuthSession — the auth state the router listens to
│   ├── storage/       SecureStorage — the token
│   └── theme/         AppTheme (tokens) + warm_widgets (WarmCard, PriorityChip, …)
└── features/
    ├── auth/          login, register, verify phone, settings, memberships
    ├── requests/      today, shopping, quick add, detail, actions
    ├── places/        saved places, nearby store lists
    ├── pantry/        recurring essentials
    └── feedback/      report a bug, follow what happened to it
```

Inside a feature:

```
domain/       entities (Equatable) + the repository interface
data/         models (fromJson) + datasource (Dio) + repository impl
presentation/ bloc (sealed events and states) + pages + local widgets
```

Rules:

- **`AppFailure` for every feature except `auth`**, which throws `AuthFailure`.
  Repositories convert `DioException` with `_guard` + `_messageFrom`.
- **JSON is parsed only in `data/models`.** The bloc never sees a `Map`.
- **Blocs are registered `registerFactory`, data as `registerLazySingleton`.**
  Each screen creates its own bloc with a local `BlocProvider`.

## Adding a feature

The full checklist, in order. Missing step 11 or 12 is a runtime crash, not a
compile error.

1. `domain/entities/<entity>.dart` — `Equatable` entity + `props`
2. `domain/repositories/<feature>_repository.dart` — the interface
3. `data/models/<entity>_model.dart` — `extends` the entity + `fromJson`
4. `data/datasources/<feature>_remote_datasource.dart` — Dio, one method per call
5. `data/repositories/<feature>_repository_impl.dart` — `_guard` → `AppFailure`
6. `presentation/bloc/<feature>_event.dart` — sealed, past tense
7. `presentation/bloc/<feature>_state.dart` — Initial / Loading / Loaded / ActionSuccess / Failure
8. `presentation/bloc/<feature>_bloc.dart` — register every event in the constructor
9. `presentation/pages/<feature>_page.dart` — wrapper creating the bloc + a private view
10. *optional* `presentation/widgets/…`
11. **`lib/core/di/injector.dart`** — datasource, repository, and the bloc factory
12. **`lib/core/router/app_router.dart`** — the `GoRoute` (a tab also needs a
    `MainShell.destinations` entry)
13. `test/feature/<feature>_bloc_test.dart` — `blocTest` + a mocked repository

Then: `dart format .` → `flutter analyze` → `flutter test`.

## Testing

| Layer | Location | Proves |
|---|---|---|
| Unit | `test/unit` | Pure Dart: the geofence evaluator, the notification planner |
| Feature | `test/feature` | Bloc transitions against a mocked repository |
| Integration | `test/integration` | Real widgets with a real bloc and a mocked repository |

```bash
flutter analyze                 # expect: No issues found
flutter test                    # expect: 37 passing
flutter test test/feature       # one layer
```

Two traps already handled, in `TESTING.md`: `BlocProvider` subscribes to a bloc's
stream, so a *mocked* bloc fails with a `_TypeError` — use a real bloc and stub the
repository; and `any()` on a non-nullable type needs `registerFallbackValue` in
`setUpAll`.

## Design

`lib/core/theme/app_theme.dart` holds the Warm Sage tokens (colours, radii, the
8-point spacing scale, elevation, the type scale) and
`lib/core/theme/warm_widgets.dart` the shared widgets: `WarmCard`,
`PriorityChip`, `StatPill`, `SectionHeader`, `WarmEmptyState`.

Screens compose those; `AppTheme.space4` rather than `16`. The full token
reference is in `Docs/design-system.md`.

Plus Jakarta Sans is applied through `google_fonts`, which fetches the face on
first use. To remove that runtime fetch, drop the TTFs into `assets/fonts/` and
declare them under `fonts:` in `pubspec.yaml` — the package prefers bundled files.

## Documentation

`Docs/` at the monorepo root holds the PRD, architecture, design system and API
reference. They are not part of this repository yet; this README and `TESTING.md`
are.
