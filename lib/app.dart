import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/app_constants.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/providers/navigation_provider.dart';
import 'package:sello/screens/auth/auth_shell.dart';
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
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
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

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const _LoggedInShell() : const AuthShell();
  }
}

class _LoggedInShell extends StatefulWidget {
  const _LoggedInShell();

  @override
  State<_LoggedInShell> createState() => _LoggedInShellState();
}

class _LoggedInShellState extends State<_LoggedInShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      context.read<DashboardProvider>().load(userId);
    });
  }

  @override
  Widget build(BuildContext context) => const MainShell();
}
