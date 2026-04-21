import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  bool register = false;
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Familia Pro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(register ? 'Crear cuenta' : 'Iniciar sesión',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                if (register) ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre visible'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 16),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                            error = null;
                          });
                          try {
                            if (register) {
                              await auth.signUp(
                                emailCtrl.text.trim(),
                                passCtrl.text,
                                nameCtrl.text.trim(),
                              );
                            } else {
                              await auth.signIn(
                                emailCtrl.text.trim(),
                                passCtrl.text,
                              );
                            }
                          } catch (e) {
                            setState(() => error = e.toString());
                          } finally {
                            if (mounted) {
                              setState(() => loading = false);
                            }
                          }
                        },
                  child: Text(register ? 'Crear cuenta' : 'Entrar'),
                ),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(
                    register
                        ? 'Ya tengo cuenta'
                        : 'No tengo cuenta todavía',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
