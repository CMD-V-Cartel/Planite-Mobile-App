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
2. **For Google OAuth: use the native `google_sign_in` Flutter package, NOT `signInWithOAuth()`.** After native sign-in, create the Supabase session via `signInWithIdToken()`, read `session.providerRefreshToken`, and call `POST /auth/google/sync` to push the token to the backend. This is the only reliable way to persist a long-lived refresh token for calendar sync.
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

### Google Authentication (Native SDK + Direct Token Push)

> **ARCHITECTURE DECISION (2026-03-22):** The old `signInWithOAuth()` external-browser flow is **deprecated** for this project. It was unreliable for capturing Google refresh tokens because the browser redirect loses provider tokens depending on platform/SDK version, and Supabase does not persistently expose `provider_refresh_token` after the initial callback.
>
> The new approach uses the **native Google Sign-In SDK** (`google_sign_in` Flutter package). The iOS/Android app handles the entire Google OAuth flow natively, obtains the Google refresh token on-device, and pushes it to the backend via `POST /auth/google/sync`. No client secret is needed on the backend. No server-side auth code exchange is needed.

#### Flow Overview

```
Flutter App (iOS)                    Backend (FastAPI)
    |                                   |
    |-- GoogleSignIn.signIn() --------->|  (native Google UI on device)
    |<-- idToken + accessToken          |
    |                                   |
    |-- signInWithIdToken(idToken) ---> Supabase Auth
    |<-- Supabase session (JWT)         |
    |    + provider_refresh_token       |
    |                                   |
    |-- POST /auth/google/sync -------->|
    |   { email, provider_user_id,      |-- upsert public.users
    |     google_refresh_token }        |-- encrypt & store token
    |<-- { user, oauth_id } ------------|
```

**Step 1:** Use the native `google_sign_in` package to sign in. This handles Google consent natively on the iOS device -- no external browser.

**Step 2:** Pass the Google `idToken` to `supabase.auth.signInWithIdToken()`. This creates a Supabase session and links the Google identity. The Supabase session response includes `provider_refresh_token` (the Google refresh token).

**Step 3 (CRITICAL):** Call `POST /auth/google/sync` with the Google refresh token. The backend:
- Creates or updates the `public.users` row with `auth_provider: "google"`
- Encrypts and persists the Google refresh token into `public.google_auth_tokens`
- Uses the service role key server-side, so **no bearer token is needed** from the frontend for this call

### iOS / Flutter Requirements
1. Add `google_sign_in` and `supabase_flutter` to `pubspec.yaml`.
2. Initialize Supabase with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
3. Add your **iOS OAuth Client ID** to `GoogleService-Info.plist` and configure the URL scheme in Xcode.
4. Also set the **iOS Client ID** on the Supabase Google provider (Dashboard -> Auth -> Providers -> Google -> "iOS Client ID").
5. Request the `calendar.readonly` scope if calendar sync is needed.
6. Persist the Supabase session in secure storage on-device.
7. Treat the Supabase `access_token` as the backend bearer token.

### Google Calendar / Long-Lived Access Rules

Practical rules:
- **Always call `POST /auth/google/sync` after a successful Google sign-in** that returned a non-null refresh token.
- If a later login returns `provider_refresh_token = null`, **do not call** `/auth/google/sync` -- the backend already has the token from a prior login.
- The backend only needs the refresh token for calendar sync. No `GOOGLE_OAUTH_CLIENT_SECRET` is needed for storing the token -- it is only needed later if the backend must refresh a Google access token for calendar API calls.

### Recommended Frontend Sequence For Google Sign-In
1. User taps "Continue with Google".
2. `GoogleSignIn.signIn()` triggers the native Google sign-in UI.
3. On success, pass the `idToken` to `supabase.auth.signInWithIdToken()`.
4. Read `session.providerRefreshToken` from the Supabase auth response -- this is the Google refresh token.
5. Extract the user's `email` and Google `provider_user_id` (sub).
6. **Call `POST /auth/google/sync`** with `email`, `provider_user_id`, and `google_refresh_token`.
7. Store the returned `user.user_id` locally.
8. Use `Authorization: Bearer <session.accessToken>` for all subsequent protected backend calls.

### Flutter iOS Implementation Checklist

1. Add dependencies to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  google_sign_in: ^6.0.0
```

2. Configure `GoogleSignIn` with your iOS client ID and required scopes:

```dart
final _googleSignIn = GoogleSignIn(
  clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
  scopes: [
    'email',
    'https://www.googleapis.com/auth/calendar.readonly',
  ],
);
```

3. Sign in with Google natively:

```dart
final googleUser = await _googleSignIn.signIn();
if (googleUser == null) return; // user cancelled

final googleAuth = await googleUser.authentication;
final idToken = googleAuth.idToken!;
```

4. Create the Supabase session and extract the Google refresh token:

```dart
final authResponse = await supabase.auth.signInWithIdToken(
  provider: OAuthProvider.google,
  idToken: idToken,
);
final session = authResponse.session!;
final user = authResponse.user!;
final googleRefreshToken = session.providerRefreshToken;
```

5. Extract identity data for the backend:

```dart
final email = user.email!;
final providerUserId = user.userMetadata?['sub'] as String? ?? '';
final fullName = googleUser.displayName;
final profilePicUrl = googleUser.photoUrl;
```

6. **Call `POST /auth/google/sync`** if the refresh token is non-null (no auth header needed):

```dart
if (googleRefreshToken != null) {
  final response = await http.post(
    Uri.parse('https://planiteinvite.share.zrok.io/auth/google/sync'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'provider_user_id': providerUserId,
      'google_refresh_token': googleRefreshToken,
      'full_name': fullName,
      'profile_picture_url': profilePicUrl,
    }),
  );
  // response.body contains: { user, oauth_id, message }
}
```

7. Build the backend auth header for subsequent protected calls:

```dart
final authHeader = 'Bearer ${session.accessToken}';
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

#### 2. Sync Google identity and refresh token (REQUIRED for Google sign-in)

```http
POST https://planiteinvite.share.zrok.io/auth/google/sync
Content-Type: application/json

{
  "email": "alice@gmail.com",
  "provider_user_id": "google-oauth-subject-id",
  "google_refresh_token": "<google-refresh-token-from-native-sdk>",
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
    "updated_at": "2026-03-21T22:25:28Z"
  },
  "oauth_id": 1,
  "message": "Google identity synced successfully."
}
```

What this call does server-side:
1. If no `public.users` row exists for this email: **creates** one with `auth_provider: "google"`.
2. If a row exists: **updates** it with `google_id` and `auth_provider: "google"`.
3. Encrypts the Google refresh token (if `CALENDAR_TOKEN_ENCRYPTION_KEY` is configured) and persists it into `public.google_auth_tokens`.
4. The refresh token is **never** returned in the response.
5. No `GOOGLE_OAUTH_CLIENT_SECRET` is needed for this call -- the app already has the token.

**When to call:** Immediately after every successful native Google sign-in where `session.providerRefreshToken` is non-null. If it's null, skip the call -- the backend already has the token from a prior login.

**Why this matters for calendar sync:** The `POST /planning/initiate` endpoint reads the Google refresh token from `public.google_auth_tokens` to fetch the user's calendar events. If this row is missing or the refresh token is empty, calendar sync will fail for that user with a "no OAuth token row found" error.

### Practical Flutter Decision Tree
1. User taps "Continue with Google".
2. `GoogleSignIn.signIn()` completes natively (no external browser).
3. If sign-in failed or was cancelled: surface auth failure, stop.
4. Extract `idToken` from the Google sign-in result.
5. Call `supabase.auth.signInWithIdToken(idToken: idToken)` to create the Supabase session.
6. If there is no Supabase session: stop and surface auth failure.
7. Read `session.providerRefreshToken` -- this is the Google refresh token.
8. **If `providerRefreshToken` is non-null:**
   call `POST /auth/google/sync` with `email`, `provider_user_id`, and `google_refresh_token`.
   The backend creates/updates `public.users` and stores the encrypted token.
9. **If `providerRefreshToken` is null:**
   skip the sync call -- the backend already has the token from a prior login.
10. Store the returned `user.user_id` locally.
11. Use `Authorization: Bearer <session.accessToken>` for all subsequent protected backend calls.

### What The Frontend Must Persist Locally
- Supabase `access_token`
- Supabase `refresh_token`
- backend `user_id`
- current backend user record

### What The Frontend Should Never Assume
- That `signInWithOAuth()` reliably returns Google refresh tokens -- this is why we use the native `google_sign_in` SDK instead
- That a Google-authenticated user already has a `public.users` row -- always call `POST /auth/google/sync` after native sign-in when a refresh token is available
- That backend `register/login/refresh/logout` apply to Google OAuth signup -- Google users use `POST /auth/google/sync`
- That calendar sync will work without calling `POST /auth/google/sync` -- the backend reads the refresh token from `google_auth_tokens`

Important:
- Google sign-in does **not** use an app password.
- The app reads the Google refresh token from `session.providerRefreshToken` after `signInWithIdToken()` and pushes it to the backend via `POST /auth/google/sync`.
- No `GOOGLE_OAUTH_CLIENT_SECRET` is needed on the backend for token storage. It is only needed later if the backend must refresh a Google access token for calendar API calls.
- If the frontend only needs authenticated app access, the Supabase session `access_token` is the required backend credential.
- If the frontend needs Google Calendar access (planning/scheduling), `POST /auth/google/sync` is the **required** call to persist the Google refresh token.

## 👥 Groups & Invites API

All group/invite endpoints require a Supabase JWT in the `Authorization: Bearer <token>` header. The backend extracts the caller's email from the JWT to identify the user.

### List My Groups

```http
GET https://planiteinvite.share.zrok.io/groups
Authorization: Bearer <session.accessToken>
```

Response (`200`):
```json
{
  "groups": [
    { "group_id": 7, "name": "Dubai Hackers", "created_by": 16, "created_at": "...", "updated_at": "..." }
  ]
}
```

Returns all groups the current user is a member of (as owner or member). Returns `{"groups": []}` if the user has no groups.

### Create a Group

```http
POST https://planiteinvite.share.zrok.io/groups
Authorization: Bearer <session.accessToken>
Content-Type: application/json

{ "name": "Dubai Hackers" }
```

Response (`201`):
```json
{
  "group": { "group_id": 6, "name": "Dubai Hackers", "created_by": 16, "created_at": "...", "updated_at": "..." },
  "membership": { "membership_id": 12, "user_id": 16, "group_id": 6, "role": "owner", "joined_at": "..." },
  "message": "Group created successfully."
}
```

The creator is automatically added to `group_members` with `role: "owner"`.

### Delete a Group (Owner Only)

```http
DELETE https://planiteinvite.share.zrok.io/groups/{group_id}
Authorization: Bearer <session.accessToken>
```

Returns `200` with `{"message": "Group deleted successfully."}`. Non-owners get `403`.

### List Group Members

```http
GET https://planiteinvite.share.zrok.io/groups/{group_id}/members
Authorization: Bearer <session.accessToken>
```

Response (`200`):
```json
{
  "group_id": 6,
  "members": [
    { "membership_id": 12, "user_id": 16, "group_id": 6, "role": "owner", "joined_at": "..." },
    { "membership_id": 13, "user_id": 18, "group_id": 6, "role": "member", "joined_at": "..." }
  ]
}
```

### Invite a User to a Group

```http
POST https://planiteinvite.share.zrok.io/groups/{group_id}/invite
Authorization: Bearer <session.accessToken>
Content-Type: application/json

{ "invitee_email": "friend@example.com" }
```

Response (`201`):
```json
{
  "invite": { "id": 1, "group_id": 6, "inviter_id": 16, "invitee_email": "friend@example.com", "status": "pending", "created_at": "..." },
  "message": "Invite sent successfully."
}
```

The caller must be a member of the group to send invites. Duplicate pending invites to the same email return `409`.

### List My Pending Invites

```http
GET https://planiteinvite.share.zrok.io/invites/me
Authorization: Bearer <session.accessToken>
```

Response (`200`):
```json
{
  "invites": [
    { "id": 1, "group_id": 6, "inviter_id": 16, "invitee_email": "friend@example.com", "status": "pending", "created_at": "..." }
  ]
}
```

Returns all invites where `invitee_email` matches the caller's email and `status` is `pending`.

### Accept or Reject an Invite

```http
POST https://planiteinvite.share.zrok.io/invites/{invite_id}/respond
Authorization: Bearer <session.accessToken>
Content-Type: application/json

{ "action": "accept" }
```

`action` must be `"accept"` or `"reject"`.

Response (`200`):
```json
{
  "message": "Invite accepted.",
  "invite": { "id": 1, "group_id": 6, "inviter_id": 16, "invitee_email": "friend@example.com", "status": "accepted", "created_at": "..." }
}
```

On accept, the invitee is automatically inserted into `group_members` with `role: "member"`. Only the invitee (matched by email) can respond. Already-responded invites return `409`.

### Error Codes

| Code | Condition |
|------|-----------|
| 401 | Missing or invalid JWT |
| 403 | Not a group member (invite) / Not the owner (delete) / Invite not addressed to you |
| 404 | Group, user, or invite not found |
| 409 | Duplicate pending invite / Invite already responded to |

### Typical Flutter Flow

```dart
// 1. Fetch my groups (e.g. on app home screen)
final groupsRes = await http.get(
  Uri.parse('$baseUrl/groups'),
  headers: {'Authorization': authHeader},
);
final myGroups = jsonDecode(groupsRes.body)['groups'];

// 2. Create a group
final createRes = await http.post(
  Uri.parse('$baseUrl/groups'),
  headers: {'Authorization': authHeader, 'Content-Type': 'application/json'},
  body: jsonEncode({'name': 'Dubai Hackers'}),
);
final groupId = jsonDecode(createRes.body)['group']['group_id'];

// 3. Invite someone
await http.post(
  Uri.parse('$baseUrl/groups/$groupId/invite'),
  headers: {'Authorization': authHeader, 'Content-Type': 'application/json'},
  body: jsonEncode({'invitee_email': 'friend@example.com'}),
);

// 4. Invitee checks their pending invites
final myInvites = await http.get(
  Uri.parse('$baseUrl/invites/me'),
  headers: {'Authorization': inviteeAuthHeader},
);

// 5. Invitee accepts
final inviteId = jsonDecode(myInvites.body)['invites'][0]['id'];
await http.post(
  Uri.parse('$baseUrl/invites/$inviteId/respond'),
  headers: {'Authorization': inviteeAuthHeader, 'Content-Type': 'application/json'},
  body: jsonEncode({'action': 'accept'}),
);
```

---

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
4. Implement Google sign-in via native `google_sign_in` SDK -> `signInWithIdToken()` for Supabase session -> `POST /auth/google/sync` with the refresh token -> use protected backend routes.
5. Implement token refresh using `/auth/refresh` before treating a session as expired.
6. Implement logout by calling `/auth/logout`, then clearing local auth state.

## Backend Resume Note
- Latest backend resume source is `plan/MEMORY.md`.
- As of 2026-03-22 (Phase 7 -- Native OAuth):
  - planning/session availability flow is live
  - `busy_window` is the primary interval field in `calendar_snapshots`
  - service-role-backed calendar sync code is implemented
  - **Identity gap resolved via native SDK approach:** The iOS app uses `google_sign_in` natively, calls `signInWithIdToken()` for Supabase session, reads `session.providerRefreshToken`, and pushes it to `POST /auth/google/sync`. No server-side auth code exchange is needed. No client secret is needed on the backend for token storage.
  - **For calendar API calls** (reading events): `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` must be set in `.env` so the backend can refresh the Google access token when calling the Calendar API

## 📚 Required Backend References
- `plan/API_SPEC.md`
- `plan/MEMORY.md`
- `openapi.json`

If the frontend repo follows this file, it should not need extra backend clarification for auth integration.
