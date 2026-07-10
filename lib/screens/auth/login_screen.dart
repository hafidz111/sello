import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_safe_area.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/login/login_form.dart';
import 'package:sello/widgets/features/login/login_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await context.read<DashboardProvider>().load(
            context.read<AuthProvider>().userId,
          );
    } else {
      AppSnackbar.warning(context, 'Email dan password wajib diisi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.headerGradient,
        ),
        child: AppSafeArea(
          bottom: true,
          responsive: false,
          child: Column(
            children: [
              SizedBox(height: Responsive.isTablet(context) ? 64 : 48),
              const LoginHeader(),
              SizedBox(height: Responsive.isTablet(context) ? 40 : 32),
              Expanded(
                child: LoginForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePassword,
                  isLoading: _isLoading,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onSubmit: _handleLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
