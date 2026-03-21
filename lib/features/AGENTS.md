
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
2. **Forward bearer tokens exactly.** Protected backend routes rely on `Authorization: Bearer <access_token>`.
3. **Assume RLS is active.** If a protected request fails, first verify the access token is present and fresh.
4. **Treat zrok as the active public tunnel.** Do not switch the frontend to Cloudflare from this environment.

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
There is currently **no backend `/auth/google` endpoint**. The frontend must start Google sign-in with Supabase directly, then use the returned Supabase session against the backend.

Use the Supabase Flutter client flow:

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

### Android / Flutter Requirements
1. Use `supabase_flutter` for the OAuth flow and session handling.
2. Configure Android deep linking so the Supabase OAuth redirect returns to the app.
3. **Local env:** copy `.env.example` → `.env` and see `docs/ENV_SETUP.md` for redirect URL + Google provider setup.
3. The app must handle the Supabase auth callback on launch/resume before trying to read session state.
4. Persist the Supabase session in secure storage on-device.
5. Treat the Supabase `access_token` as the backend bearer token.

### Google Calendar / Long-Lived Access Rules
If the app needs Google Calendar access, the Google OAuth flow must be configured to allow offline access.

Practical rule for the frontend:
- **Persist the first non-null Google refresh token you ever receive.**
- Google often **does not return a new refresh token on every login**.
- If a later login returns `refresh_token = null`, **do not overwrite** the previously stored Google refresh token in your backend DB.

That means your token sync logic should be:
1. Read the current stored `google_auth_tokens` row for the user if one exists.
2. If Google returned a new non-null refresh token, update it.
3. If Google returned `null`, keep the existing stored refresh token.

The frontend should then:
1. Persist the Supabase `access_token` and `refresh_token`.
2. Call backend protected routes with `Authorization: Bearer <access_token>`.
3. Create or update the app-level `users` row with:
   - `auth_provider: "google"`
   - `email`
   - `username`
   - `full_name`
   - `profile_picture_url`
   - `google_id`
4. Optionally persist Google token details in `POST /google-auth-tokens` if the app needs them for later Google API access.

### Recommended Frontend Sequence For Google Sign-In
1. Start Google OAuth with Supabase.
2. Wait for Supabase to finish the redirect and hydrate the session.
3. Read the Supabase session:
   - app bearer token: `session.accessToken`
   - app refresh token: `session.refreshToken`
4. Read the Google identity/profile information from the authenticated user object.
5. Call backend protected endpoints with the Supabase bearer token.
6. Ensure the app-level `users` row exists with `auth_provider: "google"`.
7. Create or update `/google-auth-tokens` with the latest Google token material.
8. Only replace the stored Google refresh token if the latest OAuth result actually includes one.

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
7. Build the backend auth header:

```dart
final authHeader = 'Bearer ${session!.accessToken}';
```

8. Ensure the app user exists in backend `users`.
   Recommended approach:
   - first try `GET /users/me`
   - if no row exists for this Google user, `POST /users`
   - if a row exists and profile data changed, `PATCH /users/{user_id}`

### Backend Calls The Flutter App Should Make

#### 1. Confirm backend health

```http
GET https://planiteinvite.share.zrok.io/health
```

Expected:

```json
{"status":"ok"}
```

#### 2. Read current authenticated app user

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

#### 3. Create backend app user if missing

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

#### 4. Update backend app user if needed

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

#### 5. Check existing stored Google tokens

```http
GET https://planiteinvite.share.zrok.io/google-auth-tokens
Authorization: Bearer <supabase_access_token>
```

Use this to determine:
   - whether a token row already exists
   - whether an older non-null Google refresh token is already stored

#### 6. Create Google token row if missing

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

#### 7. Update Google token row safely

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
3. If there is no Supabase session:
   stop and surface auth failure.
4. If session exists:
   call `GET /users/me`.
5. If backend user exists:
   update profile only if needed.
6. If backend user does not exist:
   create backend user with `auth_provider: "google"`.
7. Read `/google-auth-tokens`.
8. If no token row exists:
   create one.
9. If token row exists:
   patch access token / id token / expiry.
10. Only patch `refresh_token` when Google gives you a new non-null one.

### What The Frontend Must Persist Locally
- Supabase `access_token`
- Supabase `refresh_token`
- backend `user_id`
- current backend user record
- optionally the local timestamp for Google token expiry checks

### What The Frontend Should Never Assume
- That Google will return a refresh token every login
- That a Google-authenticated user already has a `users` row
- That backend `register/login/refresh/logout` apply to Google OAuth signup
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
- The refresh token for OAuth comes from the Supabase session and, if Google issues one, may also be stored in `google_auth_tokens.refresh_token`.
- If the frontend only needs authenticated app access, the Supabase session `access_token` is the required backend credential.
- If the frontend needs Google Calendar access, `google_auth_tokens` is the backend table intended to persist Google provider tokens.
- The backend currently exposes CRUD for `/google-auth-tokens`, but it does **not** yet exchange Google codes/tokens on behalf of the frontend.

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
4. Implement Google OAuth through Supabase, then create/update app data through protected backend routes.
5. Implement token refresh using `/auth/refresh` before treating a session as expired.
6. Implement logout by calling `/auth/logout`, then clearing local auth state.

## 📚 Required Backend References
- `plan/API_SPEC.md`
- `plan/MEMORY.md`
- `openapi.json`

If the frontend repo follows this file, it should not need extra backend clarification for auth integration.
