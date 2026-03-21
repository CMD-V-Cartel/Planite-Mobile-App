# Planning & Invite App - Frontend Mission Profile

## 🛠 Tech Stack & Integration Surface
- **Frontend Repo:** Separate repository from this backend
- **Backend Framework:** FastAPI (Python 3.12+)
- **Backend Auth Provider:** Supabase Auth
- **Database:** Supabase PostgreSQL with RLS enabled
- **Public API URL:** `https://planiteinvite.share.zrok.io`
- **OpenAPI Artifact:** `openapi.json` in the backend repo root

## 🔐 Credentials & Runtime Inputs
- **SUPABASE_URL:** `https://kjzcqnidhltsapzvduos.supabase.co`
- **SUPABASE_ANON_KEY / SUPABASE_KEY:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtqemNxbmlkaGx0c2FwenZkdW9zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0ODgxNzksImV4cCI6MjA4OTA2NDE3OX0.2iSMDERYakRZmA9GLGVyVGqhQyL_uMwaDfHdqDF6EXM`
- **Auth Mode:** Email confirmation is disabled in Supabase dashboard
- **Bearer Tokens:** Backend returns access and refresh tokens; frontend must persist both

## 🧠 Integration Rules
1. **Use backend auth endpoints first.** Do not bypass FastAPI for signup/login/logout/refresh unless explicitly asked.
2. **For Google OAuth: always call `POST /auth/google/sync` after Supabase OAuth completes.** This is the only way to ensure `public.users` and `public.google_auth_tokens` are populated, which is required for calendar sync.
3. **Forward bearer tokens exactly.** Protected backend routes rely on `Authorization: Bearer <access_token>`.
4. **Assume RLS is active.** If a protected request fails, first verify the access token is present and fresh.
5. **Treat zrok as the active public tunnel.** Do not switch the frontend to Cloudflare from this environment.

## 🤖 Frontend Roles

### @master (Orchestrator)
- Keeps frontend state, route guards, and token persistence aligned with the backend contract.
- Uses `plan/MEMORY.md` and this file as the source of truth before asking backend questions.

### @dev (UI / Auth Flow)
- Implements login, registration, refresh, and logout flows against the backend endpoints below.
- Must store `access_token`, `refresh_token`, and `token_type` from backend responses.

### @qa (Validation)
- Verifies auth flows against `https://planiteinvite.share.zrok.io`.
- Must test both anonymous and authenticated requests.

### @documentation (Consumer Docs)
- Keeps frontend env docs, API client wrappers, and auth flow docs aligned with this file and `plan/API_SPEC.md`.

## 🌐 Networking & Environment

### Active Backend Targets

| Target | URL | Purpose |
|--------|-----|---------|
| Public | `https://planiteinvite.share.zrok.io` | Primary frontend integration target |

### Why zrok Is the Current Public Tunnel
- `zrok` is the working public ingress for this backend.
- Prior Cloudflare tunnel attempts failed because outbound port `7844` is blocked from this host network.
- Do not point the frontend at any `.trycloudflare.com` URL from this environment.

### Health Checks
- Public health: `GET https://planiteinvite.share.zrok.io/health`
- Expected body:

```json
{"status":"ok"}
```

## 🔐 Auth Contract

### `POST /auth/register`
Creates a Supabase Auth user and inserts the matching row into `public.users`.

Request:

```json
{
  "email": "alice@example.com",
  "password": "supersecret1",
  "username": "alice",
  "full_name": "Alice Example",
  "profile_picture_url": null
}
```

Response:

```json
{
  "user": {
    "user_id": 1,
    "email": "alice@example.com",
    "username": "alice",
    "full_name": "Alice Example",
    "profile_picture_url": null,
    "auth_provider": "email",
    "google_id": null,
    "password_hash": null,
    "mfa_enabled": false,
    "mfa_secret": null,
    "last_login_at": null,
    "is_active": true,
    "created_at": "2026-03-21T17:04:23.617772Z",
    "updated_at": "2026-03-21T17:04:23.617772Z"
  },
  "access_token": "<jwt>",
  "refresh_token": "<refresh-token>",
  "token_type": "bearer"
}
```

### `POST /auth/login`
Exchanges email/password credentials for a Supabase session.

Request:

```json
{
  "email": "alice@example.com",
  "password": "supersecret1"
}
```

Response:

```json
{
  "user": {
    "email": "alice@example.com"
  },
  "access_token": "<jwt>",
  "refresh_token": "<refresh-token>",
  "token_type": "bearer"
}
```

### `POST /auth/refresh`
Refreshes the session using the stored refresh token.

Request:

```json
{
  "refresh_token": "<refresh-token>"
}
```

Response:

```json
{
  "user": {
    "email": "alice@example.com"
  },
  "access_token": "<new-jwt>",
  "refresh_token": "<new-refresh-token>",
  "token_type": "bearer"
}
```

### `POST /auth/logout`
Invalidates the current session.

Request headers:

```text
Authorization: Bearer <access-token>
```

Response:

```json
{
  "message": "Logged out successfully."
}
```

### Google Authentication

Google sign-in starts with the Supabase OAuth flow. After the redirect completes, the frontend **must** call `POST /auth/google/sync` to bridge the identity gap between `auth.users` (Supabase-managed) and `public.users` + `public.google_auth_tokens` (app-managed). Without this call, calendar sync will not work for the user.

**Step 1:** Start Google OAuth via Supabase:

```ts
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
)
```

After the OAuth redirect completes, Supabase provides a session containing:
- `access_token`
- `refresh_token`
- `user`
- provider metadata in `user.app_metadata` / `user.identities`

**Step 2: (CRITICAL)** Call `POST /auth/google/sync` immediately after the OAuth redirect succeeds. This single call handles everything the backend needs:
- Creates or updates the `public.users` row with `auth_provider: "google"`
- Encrypts and persists the Google refresh token into `public.google_auth_tokens`
- Uses the service role key server-side, so no bearer token is needed from the frontend for this call

See the full `POST /auth/google/sync` contract below.

### Android / Flutter Requirements
1. Use `supabase_flutter` for the OAuth flow and session handling.
2. Configure Android deep linking so the Supabase OAuth redirect returns to the app.
3. The app must handle the Supabase auth callback on launch/resume before trying to read session state.
4. Persist the Supabase session in secure storage on-device.
5. Treat the Supabase `access_token` as the backend bearer token.

### Google Calendar / Long-Lived Access Rules
If the app needs Google Calendar access, the Google OAuth flow must be configured to allow offline access.

Practical rule for the frontend:
- **Persist the first non-null Google refresh token you ever receive.**
- Google often **does not return a new refresh token on every login**.
- If a later login returns `refresh_token = null`, **do not call** `POST /auth/google/sync` with an empty/null token. Only call it when you have a real token to persist.

The frontend should:
1. Persist the Supabase `access_token` and `refresh_token` locally.
2. Call `POST /auth/google/sync` with the user's email, Google `provider_user_id` (from `user.identities`), and the Google refresh token. This single call creates/updates both `public.users` and `public.google_auth_tokens`.
3. Call backend protected routes with `Authorization: Bearer <access_token>`.
4. The old multi-step flow (GET `/users/me` -> POST `/users` -> GET/POST/PATCH `/google-auth-tokens`) still works but is **no longer the recommended path**. Use `POST /auth/google/sync` instead.

### Recommended Frontend Sequence For Google Sign-In
1. Start Google OAuth with Supabase.
2. Wait for Supabase to finish the redirect and hydrate the session.
3. Read the Supabase session:
   - app bearer token: `session.accessToken`
   - app refresh token: `session.refreshToken`
4. Extract the Google identity from the Supabase user object:
   - `provider_user_id`: from `user.identities` where `provider == "google"` -> `identity.id`
   - `email`: from `user.email`
   - `google_refresh_token`: from the provider token data (only available if offline access was requested)
5. **Call `POST /auth/google/sync`** with the extracted data. This single call:
   - Creates or updates the `public.users` row
   - Encrypts and persists the Google refresh token into `public.google_auth_tokens`
   - Returns the full user object and `oauth_id`
6. Store the returned `user.user_id` locally.
7. Call backend protected endpoints with the Supabase bearer token.
8. Only call `POST /auth/google/sync` again on subsequent logins if Google provides a new non-null refresh token.

### Flutter Android Implementation Checklist
1. Add and configure `supabase_flutter` in the Flutter app.
2. Initialize Supabase with:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Configure Android deep linking for the Supabase auth callback.
4. Start Google OAuth:

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
);
```

5. After redirect completion, read the active session:

```dart
final session = supabase.auth.currentSession;
final user = supabase.auth.currentUser;
```

6. Validate that the session exists before calling the backend:
   - `session?.accessToken != null`
   - `session?.refreshToken != null`
   - `user?.email != null`

7. Extract the Google identity:

```dart
final googleIdentity = user!.identities?.firstWhere(
  (id) => id.provider == 'google',
);
final providerUserId = googleIdentity?.id ?? '';
final email = user.email!;
```

8. **Call `POST /auth/google/sync`** (no auth header needed -- uses service role server-side):

```dart
final response = await http.post(
  Uri.parse('https://planiteinvite.share.zrok.io/auth/google/sync'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'provider_user_id': providerUserId,
    'google_refresh_token': googleRefreshToken, // only if non-null
    // optional: 'username', 'full_name', 'profile_picture_url'
  }),
);
// response.body contains: { user, oauth_id, message }
```

9. Build the backend auth header for subsequent protected calls:

```dart
final authHeader = 'Bearer ${session!.accessToken}';
```

### Backend Calls The Flutter App Should Make

#### 1. Confirm backend health

```http
GET https://planiteinvite.share.zrok.io/health
```

Expected:

```json
{"status":"ok"}
```

#### 2. Sync Google identity (RECOMMENDED -- single call replaces steps 3-7)

```http
POST https://planiteinvite.share.zrok.io/auth/google/sync
Content-Type: application/json

{
  "email": "alice@gmail.com",
  "provider_user_id": "google-oauth-subject-id",
  "google_refresh_token": "<google-refresh-token>",
  "username": "alice",
  "full_name": "Alice Example",
  "profile_picture_url": "https://..."
}
```

Required fields: `email`, `provider_user_id`, `google_refresh_token`.
Optional fields: `username` (defaults to email prefix), `full_name`, `profile_picture_url`.

**No `Authorization` header is needed.** The backend uses its service role key to bypass RLS.

Expected response (`201 Created`):

```json
{
  "user": {
    "user_id": 14,
    "email": "alice@gmail.com",
    "username": "alice",
    "full_name": "Alice Example",
    "auth_provider": "google",
    "google_id": "google-oauth-subject-id",
    "is_active": true,
    "created_at": "2026-03-21T22:25:28Z",
    "updated_at": "2026-03-21T22:25:28Z",
    ...
  },
  "oauth_id": 1,
  "message": "Google identity synced successfully."
}
```

What this call does:
- If no `public.users` row exists for this email: **creates** one with `auth_provider: "google"`.
- If a row exists: **updates** it with `google_id` and `auth_provider: "google"`.
- If no `public.google_auth_tokens` row exists for this user_id: **creates** one with the encrypted refresh token.
- If a row exists: **updates** the `provider_user_id` and `refresh_token`.
- The `google_refresh_token` is encrypted server-side if `CALENDAR_TOKEN_ENCRYPTION_KEY` is configured.
- The refresh token is **never** returned in the response.

**When to call:** Immediately after every successful Google OAuth redirect where Google returned a non-null refresh token. If Google did not return a refresh token, skip this call to avoid overwriting the previously stored token.

**Why this matters for calendar sync:** The `POST /planning/initiate` endpoint reads the Google refresh token from `public.google_auth_tokens` to fetch the user's calendar events. If this row is missing or the refresh token is empty, calendar sync will fail for that user with a "no OAuth token row found" error.

---

The steps below (3-7) are the **legacy multi-step alternative**. Use them only if you cannot use `POST /auth/google/sync`.

#### 3. Read current authenticated app user (legacy)

```http
GET https://planiteinvite.share.zrok.io/users/me
Authorization: Bearer <supabase_access_token>
```

Expected shape:

```json
{
  "items": [
    {
      "user_id": 1,
      "email": "alice@gmail.com",
      "username": "alice",
      "full_name": "Alice Example",
      "profile_picture_url": "https://...",
      "auth_provider": "google",
      "google_id": "google-oauth-subject-id",
      "password_hash": null,
      "mfa_enabled": false,
      "mfa_secret": null,
      "last_login_at": null,
      "is_active": true,
      "created_at": "2026-03-21T17:04:23.617772Z",
      "updated_at": "2026-03-21T17:04:23.617772Z"
    }
  ]
}
```

#### 4. Create backend app user if missing (legacy)

```http
POST https://planiteinvite.share.zrok.io/users
Authorization: Bearer <supabase_access_token>
Content-Type: application/json

{
  "email": "alice@gmail.com",
  "username": "alice",
  "full_name": "Alice Example",
  "profile_picture_url": "https://...",
  "auth_provider": "google",
  "google_id": "google-oauth-subject-id",
  "mfa_enabled": false,
  "is_active": true
}
```

#### 5. Update backend app user if needed (legacy)

```http
PATCH https://planiteinvite.share.zrok.io/users/{user_id}
Authorization: Bearer <supabase_access_token>
Content-Type: application/json

{
  "full_name": "Alice Example",
  "profile_picture_url": "https://...",
  "google_id": "google-oauth-subject-id"
}
```

#### 6. Check existing stored Google tokens (legacy)

```http
GET https://planiteinvite.share.zrok.io/google-auth-tokens
Authorization: Bearer <supabase_access_token>
```

Use this to determine:
   - whether a token row already exists
   - whether an older non-null Google refresh token is already stored

#### 7. Create Google token row if missing (legacy)

```http
POST https://planiteinvite.share.zrok.io/google-auth-tokens
Authorization: Bearer <supabase_access_token>
Content-Type: application/json

{
  "user_id": 1,
  "provider_user_id": "google-oauth-subject-id",
  "access_token": "<google-access-token>",
  "refresh_token": "<google-refresh-token-if-present>",
  "id_token": "<google-id-token>",
  "expires_at": "2026-03-21T18:00:00Z"
}
```

#### 8. Update Google token row safely (legacy)

```http
PATCH https://planiteinvite.share.zrok.io/google-auth-tokens/{oauth_id}
Authorization: Bearer <supabase_access_token>
Content-Type: application/json

{
  "access_token": "<latest-google-access-token>",
  "id_token": "<latest-google-id-token>",
  "expires_at": "2026-03-21T18:30:00Z"
}
```

If a new Google refresh token is present, include:

```json
{
  "refresh_token": "<new-google-refresh-token>"
}
```

If Google did **not** return a refresh token this time:
   - do **not** send `refresh_token: null`
   - do **not** erase the previously stored refresh token

### Practical Flutter Decision Tree
1. User taps `Continue with Google`.
2. Supabase OAuth completes.
3. If there is no Supabase session: stop and surface auth failure.
4. Extract `email`, `provider_user_id` from the Supabase user object.
5. Extract the Google refresh token from the provider token data.
6. **If Google returned a non-null refresh token:**
   call `POST /auth/google/sync` with `email`, `provider_user_id`, and `google_refresh_token`.
   This creates/updates the `public.users` row AND persists the encrypted refresh token.
7. **If Google did NOT return a refresh token:**
   call `POST /auth/google/sync` only if you have a previously stored refresh token to send.
   Otherwise skip the call -- the backend already has the token from a prior login.
8. Store the returned `user.user_id` locally.
9. Use `Authorization: Bearer <session.accessToken>` for all subsequent protected backend calls.

### What The Frontend Must Persist Locally
- Supabase `access_token`
- Supabase `refresh_token`
- backend `user_id`
- current backend user record
- optionally the local timestamp for Google token expiry checks

### What The Frontend Should Never Assume
- That Google will return a refresh token every login -- only call `/auth/google/sync` when you have a real token
- That a Google-authenticated user already has a `public.users` row -- always call `/auth/google/sync` after the first OAuth redirect
- That backend `register/login/refresh/logout` apply to Google OAuth signup -- Google users use `/auth/google/sync` instead
- That calendar sync will work without calling `/auth/google/sync` -- the backend reads the refresh token from `google_auth_tokens`
- That clearing the local session is enough without syncing persisted backend token rows when needed

Example protected user payload after Google OAuth:

```json
{
  "email": "alice@gmail.com",
  "username": "alice",
  "full_name": "Alice Example",
  "profile_picture_url": "https://...",
  "auth_provider": "google",
  "google_id": "google-oauth-subject-id",
  "mfa_enabled": false,
  "is_active": true
}
```

Example protected Google token payload:

```json
{
  "user_id": 1,
  "provider_user_id": "google-oauth-subject-id",
  "access_token": "<google-access-token>",
  "refresh_token": "<google-refresh-token-if-present>",
  "id_token": "<google-id-token>",
  "expires_at": "2026-03-21T18:00:00Z"
}
```

Important:
- Google sign-in does **not** use an app password.
- The refresh token for OAuth comes from the Supabase session and, if Google issues one, must be sent to `POST /auth/google/sync` for server-side persistence.
- If the frontend only needs authenticated app access, the Supabase session `access_token` is the required backend credential.
- If the frontend needs Google Calendar access (planning/scheduling), `POST /auth/google/sync` is the **required** call to persist the Google refresh token into `google_auth_tokens`.
- The backend also exposes raw CRUD for `/google-auth-tokens`, but `POST /auth/google/sync` is the recommended single-call path that handles user creation, token encryption, and service-role RLS bypass automatically.

## 📦 Protected Data Access

### Auth Header
For protected backend calls, send:

```text
Authorization: Bearer <access_token>
```

### Key Protected Resource
- `GET /users`
- `GET /users/me`
- `POST /users`
- `PATCH /users/{user_id}`
- `DELETE /users/{user_id}`

The backend forwards the bearer token to Supabase PostgREST, so frontend auth state must stay synchronized with backend-issued tokens.

## 🧱 Primary User Shape

```ts
type User = {
  user_id: number;
  email: string;
  username: string;
  full_name: string | null;
  profile_picture_url: string | null;
  auth_provider: "email" | "google";
  google_id: string | null;
  password_hash: string | null;
  mfa_enabled: boolean;
  mfa_secret: string | null;
  last_login_at: string | null;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};
```

## 🚀 Frontend Execution Strategy
1. Use `GET /health` to confirm the backend target before debugging UI logic.
2. Implement `register -> persist tokens -> fetch protected data`.
3. Implement `login -> persist tokens -> fetch protected data`.
4. Implement Google OAuth through Supabase, then call `POST /auth/google/sync` to bridge the identity gap, then use protected backend routes.
5. Implement token refresh using `/auth/refresh` before treating a session as expired.
6. Implement logout by calling `/auth/logout`, then clearing local auth state.

## Backend Resume Note
- Latest backend resume source is `plan/MEMORY.md`.
- As of 2026-03-21 (Phase 6.5):
  - planning/session availability flow is live
  - `busy_window` is the primary interval field in `calendar_snapshots`
  - service-role-backed calendar sync code is implemented
  - **Identity gap resolved:** `POST /auth/google/sync` is live and closes the gap between `auth.users` and `public.users` + `public.google_auth_tokens`
  - `allenfencer316@gmail.com` has been synced: `public.users` row (`user_id=14`) and `public.google_auth_tokens` row (`oauth_id=1`) both exist
  - To complete a real Google Calendar sync, the dummy refresh token for `allenfencer316@gmail.com` must be replaced with the user's actual Google OAuth refresh token by calling `POST /auth/google/sync` from the frontend after a real OAuth flow

## 📚 Required Backend References
- `plan/API_SPEC.md`
- `plan/MEMORY.md`
- `openapi.json`

If the frontend repo follows this file, it should not need extra backend clarification for auth integration.
