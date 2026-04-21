import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final inviteCtrl = TextEditingController();
  String role = 'adult';

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final auth = ref.watch(authServiceProvider);
    final service = ref.watch(familyServiceProvider);

    return ListView(
      children: [
        Text('Ajustes', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        familiesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (families) {
            final current = families.firstWhere(
              (f) => f.isCurrent,
              orElse: () => families.first,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    title: Text(current.name),
                    subtitle: Text('Rol actual: ${current.role}'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: inviteCtrl,
                  decoration: const InputDecoration(labelText: 'Invitar por email'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'adult', child: Text('Adult')),
                    DropdownMenuItem(value: 'child', child: Text('Child')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'adult'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    if (inviteCtrl.text.trim().isEmpty) return;
                    await service.inviteMember(
                      familyId: current.id,
                      email: inviteCtrl.text,
                      role: role,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitación creada')),
                      );
                    }
                    inviteCtrl.clear();
                  },
                  child: const Text('Invitar'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => auth.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
