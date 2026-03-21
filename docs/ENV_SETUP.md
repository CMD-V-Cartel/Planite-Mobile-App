# Environment & Supabase Google auth

## 1. Copy env file

Copy `.env.example` to `.env` in the **project root** (same folder as `pubspec.yaml`).

```bash
cp .env.example .env
```

Fill `SUPABASE_URL` and `SUPABASE_ANON_KEY` from your Supabase project (or from `lib/features/AGENTS.md` for this hackathon).

## 2. Supabase Dashboard → Redirect URLs

Add this **Redirect URL** (must match `lib/config/supabase_oauth_config.dart`):

`io.supabase.flutter://login-callback/`

Also enable **Google** under Authentication → Providers and configure the Google OAuth client IDs.

## 3. Deep links

- **Android:** `android/app/src/main/AndroidManifest.xml` includes the `io.supabase.flutter` / `login-callback` intent filter.
- **iOS:** `ios/Runner/Info.plist` registers the `io.supabase.flutter` URL scheme.

## 4. `.gitignore`

`.env` is gitignored; only `.env.example` is committed.
