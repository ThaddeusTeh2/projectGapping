import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/app_snackbar.dart';
import '../../core/validation/validators.dart';
import '../../di/providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
    });

    final authRepo = ref.read(authRepositoryProvider);

    try {
      await authRepo.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      context.go('/bikes');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Failed to register';
      setState(() {
        _errorMessage = msg;
      });
      if (!mounted) return;
      AppSnackbar.showError(context, msg);
    } catch (_) {
      const msg = 'Failed to register';
      setState(() {
        _errorMessage = msg;
      });
      if (!mounted) return;
      AppSnackbar.showError(context, msg);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Register',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInputFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  label: const Text('Email'),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  label: const Text('Password'),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                ShadInputFormField(
                  controller: _confirmController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  label: const Text('Confirm password'),
                  validator: (v) => Validators.confirmPassword(
                    password: _passwordController.text,
                    confirm: v,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ShadButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 12),
                ShadButton.link(
                  onPressed: _isLoading ? null : () => context.go('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
