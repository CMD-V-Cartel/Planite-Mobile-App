import 'package:flutter/foundation.dart';

/// Must match Android [intent-filter] / iOS URL scheme and Supabase
/// **Authentication → URL Configuration → Redirect URLs**.
const String kSupabaseOAuthRedirect =
    'io.supabase.flutter://login-callback/';

/// OAuth redirect: web uses site URL; native uses deep link.
String? supabaseOAuthRedirectTo() {
  if (kIsWeb) {
    return null;
  }
  return kSupabaseOAuthRedirect;
}
