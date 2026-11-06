# Vehicle Tracking — Flutter Client

A Flutter dashboard for the [Vehicle Tracking backend](https://github.com/Deepanjal-s/vehicle-tracking-backend). Users sign in to view their assigned route and vehicle, current GPS location, an OpenStreetMap map, and recent location history.

## Implemented features

- Email/password login with a bearer token returned by the backend.
- Assigned route, vehicle number, and vehicle status.
- Latest location refreshed every five seconds.
- Map marker and coordinates, speed, and timestamp.
- Up to ten GPS history records loaded when the dashboard opens.
- Logout back to the login screen.

## Stack

Flutter and Dart, `http`, `flutter_map`, and `latlong2`. The current Dart SDK constraint in `pubspec.yaml` is `^3.13.4`.

## Run locally

1. Install Flutter with a Dart version compatible with `pubspec.yaml`.
2. Set up the [backend](https://github.com/Deepanjal-s/vehicle-tracking-backend) and make its API reachable at `http://127.0.0.1:8000`.
3. Clone and launch the client:

```sh
git clone https://github.com/Deepanjal-s/vehicle-tracking-flutter.git
cd vehicle-tracking-flutter
flutter pub get
flutter run
```

Use an account configured in your backend. Location data depends on the backend receiving GPS updates.

## API connection and limitations

API URLs are currently hard-coded in `lib/main.dart` to `http://127.0.0.1:8000`. On an emulator or physical phone, loopback refers to that device, not necessarily the computer running the API. Update all API URLs to an address reachable from your selected device before testing there. Browser builds also require compatible backend CORS configuration.

The token is held in memory; persistent sign-in is not implemented. Location polling refreshes the latest position, while history is loaded on dashboard entry. This is a development prototype, not a verified production tracking service.

## Code map

- `lib/main.dart`: login screen, HTTP requests, polling, dashboard, and map.
- `pubspec.yaml`: SDK constraint and dependencies.
- `test/`: test sources; run `flutter test` to check their current status.

## Next improvements

- Centralize API configuration instead of repeating URLs.
- Add tests for login, API errors, and missing GPS data.
- Add screenshots and a reproducible demo with synthetic route data.
- Improve session expiry handling and refresh history alongside location.
