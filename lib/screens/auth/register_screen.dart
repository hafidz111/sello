import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_safe_area.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/login/login_header.dart';
import 'package:sello/widgets/features/login/register_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal mendaftar. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                child: RegisterForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  isLoading: _isLoading,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onToggleConfirmPassword: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  onSubmit: _handleRegister,
                  onLogin: widget.onLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
