import 'package:flutter/material.dart';
import 'package:sello/screens/auth/forgot_password_screen.dart';
import 'package:sello/screens/auth/login_screen.dart';
import 'package:sello/screens/auth/register_screen.dart';

enum _AuthView { login, register, forgotPassword }

class AuthShell extends StatefulWidget {
  const AuthShell({super.key});

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  _AuthView _view = _AuthView.login;
  String _emailDraft = '';

  void _showLogin() {
    setState(() => _view = _AuthView.login);
  }

  void _showRegister() {
    setState(() => _view = _AuthView.register);
  }

  void _showForgotPassword(String email) {
    setState(() {
      _emailDraft = email;
      _view = _AuthView.forgotPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _AuthView.login => LoginScreen(
          initialEmail: _emailDraft,
          onEmailChanged: (email) => _emailDraft = email,
          onRegister: _showRegister,
          onForgotPassword: () => _showForgotPassword(_emailDraft),
        ),
      _AuthView.register => RegisterScreen(onLogin: _showLogin),
      _AuthView.forgotPassword => ForgotPasswordScreen(
          initialEmail: _emailDraft,
          onBack: _showLogin,
        ),
    };
  }
}
