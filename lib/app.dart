import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/app_constants.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/screens/auth/login_screen.dart';
import 'package:sello/screens/shell/main_shell.dart';
import 'package:sello/styles/app_theme.dart';

class SelloApp extends StatelessWidget {
  const SelloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return isLoggedIn ? const MainShell() : const LoginScreen();
  }
}
