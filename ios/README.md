# iOS App (SwiftUI)

This folder contains the Flex Force X MVP iOS app.

## Implemented modules

- Auth (Sign in with Apple + Email/Password)
- Onboarding + Terra connect
- Dashboard (readiness + tiles + sync status)
- Insights (7/30 day trend charts)
- Settings + support

## Project generation

This app uses **XcodeGen** for repeatable project generation.

```bash
brew install xcodegen
cd ios
xcodegen generate
open FlexForceX.xcodeproj
```

## Configure environment

Set values in:

- `ios/Config/Debug.xcconfig`
- `ios/Config/Release.xcconfig`

Required:

```text
SUPABASE_URL=<REPLACE_ME>
SUPABASE_ANON_KEY=<REPLACE_ME>
APP_DEEP_LINK_SCHEME=flexforcex
```

Deep link callback expected from Terra: `flexforcex://terra-callback`

## Notes

- The iOS app never stores raw HealthKit payloads locally.
- Terra/Health ingestion is handled via backend webhook -> normalized Supabase tables.
- App reads `biometrics_daily` + `terra_connections` for dashboard/insights/state.
