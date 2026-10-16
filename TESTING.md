# Testing

## Layers

Tests are split by **scope**, in three directories.

| Directory | Scope | Belongs here |
|---|---|---|
| `test/unit` | Pure Dart, no widgets | Geofence distance/transition maths, notification planning. |
| `test/feature` | One bloc, one feature | Auth, requests, places, pantry and voice-consent blocs driving a mocked repository. |
| `test/integration` | Real widgets wired together | The task card with the real bloc and a mocked data layer; the app shell and its bottom navigation. |

```
flutter test
flutter test test/unit
flutter test test/feature
flutter test test/integration
flutter analyze
```

Bloc tests use `bloc_test` + `mocktail`; widget tests use `flutter_test`.

## Notes

- **`BlocProvider` subscribes to the bloc**, so a mocked bloc (`class MockBloc
  extends Mock implements AuthBloc`) fails with a `_TypeError` on `stream`. Use a
  real bloc and stub the repository method the event reaches instead — see the
  `SessionLoaded` stub in `test/integration/app_shell_test.dart`.
- **`any()` needs a fallback** for non-nullable types. Register them once:
  `registerFallbackValue('')` for a `String`, `registerFallbackValue(<String,
  dynamic>{})` for a map.
- **Assert inert controls by their handler, not by tapping.** A disabled
  `InkResponse` has no gesture recognizer, so `tester.tap` throws; assert
  `expect(circle.onTap, isNull)` instead.
- **`MainShell` takes its `location` as a parameter**, so tab-highlighting can be
  tested without standing up a router.

## Manual QA

`Backend/TESTING.md` lists the seeded accounts. Point the app at your API and run
it — the mobile client talks to the **`/mobile`** surface, which mints
mobile-scoped tokens:

```
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/mobile
```

(`10.0.2.2` is the Android emulator's alias for the host machine. Use your LAN IP
for a physical device.)
