import 'package:cursor_hack/config/env.dart';
import 'package:cursor_hack/features/auth/controllers/auth_provider.dart';
import 'package:cursor_hack/features/calendar/controllers/calendar_provider.dart';
import 'package:cursor_hack/features/groups/controllers/groups_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cursor_hack/router/app_router.dart';
import 'package:cursor_hack/utils/themes/app_themes.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadEnv();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => GroupsProvider()),
            ChangeNotifierProvider(create: (_) => CalendarProvider()),
          ],
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Cursor Hack',
            theme: AppThemes.lightTheme,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
