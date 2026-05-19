import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/constants/theme.dart';

class MatchHomeApp extends StatelessWidget {
  const MatchHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MatchHome',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
