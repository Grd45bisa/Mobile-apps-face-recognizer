import 'package:flutter/material.dart';
import '../../../shared/theme/app_colors.dart';
import '../controller/auth_controller.dart';
import 'widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _controller = AuthController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _controller.sendPasswordReset(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: minimalAppBar(title: 'Lupa Password', context: context),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.status == AuthStatus.success) {
              return SuccessState(
                icon: Icons.mark_email_read_outlined,
                title: 'Email Terkirim',
                message:
                    'Link reset password telah dikirim ke\n${_emailCtrl.text.trim()}.\n\nCek folder inbox atau spam Anda.',
                actionLabel: 'Kembali ke Login',
                onAction: () => Navigator.pop(context),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoBox(),
                    const SizedBox(height: 28),
                    AuthField(
                      controller: _emailCtrl,
                      label: 'Email Akun Anda',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      onChanged: (_) => _controller.reset(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(v.trim())) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    if (_controller.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      ErrorBanner(message: _controller.errorMessage!),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Kirim Link Reset',
                      loading: _controller.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    _buildBackLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 17,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk membuat password baru.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.85),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Kembali ke Login',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
