import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/brand_header.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _email = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await getIt<DioClient>().dio.post<void>(
        '/v1/auth/forgot-password',
        data: {'email': email},
      );
      if (mounted) setState(() => _sent = true);
    } on DioException catch (error) {
      if (mounted) {
        final data = error.response?.data;
        final message = data is Map && data['message'] is String
            ? data['message'] as String
            : 'Could not send the reset link.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(AppTheme.errorSnackBar(message));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
        ),
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandHeader(subtitle: 'Household Logistics'),
                  const SizedBox(height: 28),
                  const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter the email on your account and we will send a secure reset link.',
                    style: TextStyle(fontSize: 13, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _sending || _sent ? null : _submit,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_sent ? 'Link sent' : 'Send reset link'),
                  ),
                  if (_sent) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'If that email belongs to an account, a reset link is on its way. Check spam if it does not arrive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.muted),
                    ),
                  ],
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Back to sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
