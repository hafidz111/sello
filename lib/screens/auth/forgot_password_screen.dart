import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_safe_area.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/login/forgot_password_form.dart';
import 'package:sello/widgets/features/login/login_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.initialEmail,
    required this.onBack,
  });

  final String initialEmail;
  final VoidCallback onBack;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(
            email: _emailController.text.trim(),
          );
      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Link reset password telah dikirim. Cek email kamu.',
      );
      widget.onBack();
    } on AuthException catch (error) {
      if (!mounted) return;
      AppSnackbar.error(context, error.message);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal mengirim link reset. Coba lagi.');
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
                child: ForgotPasswordForm(
                  formKey: _formKey,
                  emailController: _emailController,
                  isLoading: _isLoading,
                  onSubmit: _handleSubmit,
                  onBack: widget.onBack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
