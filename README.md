# LOTUS

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Validated toolchain

- Flutter 3.41.9 (stable release)
- Dart 3.11.5

Install dependencies with `flutter pub get`, then run `flutter analyze` before
committing changes. The resolved dependency graph is recorded in
`pubspec.lock`.

## Mapbox

The mobile Home uses Mapbox. Pass a public token when running or building:

```text
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your_public_token
```

See `docs/mapbox.md` for mobile requirements, CI setup, and lifecycle details.

## Backend

Firebase é o backend único do projeto: Authentication, Cloud Firestore, Cloud
Storage e Cloud Functions. O modelo de dados, as permissões, a migração dos
favoritos e o processo de ativação estão em `docs/backend.md`.

O centro pessoal em `/saved`, os interesses, o histórico agregado e a baseline
de recomendações estão descritos em `docs/personalization.md`.

A pesquisa em linguagem natural e o caminho futuro para pesquisa semântica
estão descritos em `docs/natural_search.md`.
