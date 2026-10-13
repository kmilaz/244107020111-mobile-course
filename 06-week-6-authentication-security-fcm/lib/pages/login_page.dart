import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

/// Halaman masuk. Berfungsi juga sebagai halaman yang dipaksa muncul oleh guard
/// route selama belum ada token tersimpan.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'mahasiswa@polinema.ac.id',
  );
  final _passwordController = TextEditingController(text: 'rahasia123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final error = auth.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Masuk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Email harus memuat @'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Kata sandi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Minimal 6 karakter'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: auth.isLoading ? null : _submit,
            child: Text(auth.isLoading ? 'Memproses…' : 'Masuk'),
          ),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text(
              _pesanRamah(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Data demo: email apa pun yang memuat "@", kata sandi minimal '
            '6 karakter. Token disimpan di secure storage, bukan '
            'SharedPreferences.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// `AsyncValue.guard` membungkus exception apa adanya, termasuk kata
/// "Exception: " di depannya. Itu tidak pantas dibaca pengguna.
String _pesanRamah(Object error) =>
    error.toString().replaceFirst('Exception: ', '');
