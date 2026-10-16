import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage> {
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your phone')),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              context.go('/home');
            } else if (state is AuthCodeSent) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('A 6-digit code has been sent by SMS.'),
                ),
              );
            } else if (state is AuthFailureState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'We will send a one-time code to your registered number.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () =>
                      context.read<AuthBloc>().add(const PhoneCodeRequested()),
                  child: const Text('Send verification code'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit code',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => FilledButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () => context.read<AuthBloc>().add(
                            PhoneVerifyRequested(_code.text.trim()),
                          ),
                    child: state is AuthLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify phone'),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
