import 'package:cursor_hack/features/auth/controllers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cursor_hack/router/app_router.dart';
import 'package:cursor_hack/utils/themes/app_themes.dart';
import 'package:provider/provider.dart';

void main() {
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
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
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
