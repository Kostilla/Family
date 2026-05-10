import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

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
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withOpacity(.22),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 42),
                    ),
                    const SizedBox(height: 18),
                    Text('Familia Pro', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 6),
                    Text(
                      'Organiza chat, compra, tareas, menús y calendario familiar en un único sitio.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    GlassPanel(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(register ? 'Crear cuenta' : 'Iniciar sesión', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            register ? 'Crea tu cuenta para empezar una familia o unirte a una.' : 'Entra para sincronizar tu familia en tiempo real.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          if (register) ...[
                            TextField(
                              controller: nameCtrl,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                                labelText: 'Nombre visible',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.mail_outline),
                              labelText: 'Email',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            onSubmitted: (_) => _submit(auth),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline),
                              labelText: 'Contraseña',
                            ),
                          ),
                          if (error != null) ...[
                            const SizedBox(height: 12),
                            Text(error!, style: TextStyle(color: scheme.error)),
                          ],
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: loading ? null : () => _submit(auth),
                            icon: loading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : Icon(register ? Icons.person_add_alt_1 : Icons.login),
                            label: Text(register ? 'Crear cuenta' : 'Entrar'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: loading ? null : () => setState(() => register = !register),
                            child: Text(register ? 'Ya tengo cuenta' : 'No tengo cuenta todavía'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(dynamic auth) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (register) {
        await auth.signUp(emailCtrl.text.trim(), passCtrl.text, nameCtrl.text.trim());
      } else {
        await auth.signIn(emailCtrl.text.trim(), passCtrl.text);
      }
      await ref.read(pushServiceProvider).initialize();
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
