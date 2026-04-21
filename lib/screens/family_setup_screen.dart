import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final nameCtrl = TextEditingController();
  bool busy = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final familyService = ref.watch(familyServiceProvider);
    final push = ref.watch(pushServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tus familias')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: familiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (families) {
            if (families.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Selecciona familia'),
                  const SizedBox(height: 12),
                  ...families.map(
                    (f) => Card(
                      child: ListTile(
                        title: Text(f.name),
                        subtitle: Text('Rol: ${f.role}'),
                        trailing: f.isCurrent ? const Icon(Icons.check_circle) : null,
                        onTap: () async {
                          await familyService.switchCurrentFamily(f.id);
                          await push.initialize();
                          if (mounted) context.go('/home');
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Crear nueva familia',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() {
                              busy = true;
                              error = null;
                            });
                            try {
                              await familyService.createFamily(nameCtrl.text.trim());
                              ref.invalidate(myFamiliesProvider);
                            } catch (e) {
                              setState(() => error = e.toString());
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    child: const Text('Crear familia'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aún no perteneces a ninguna familia.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de tu primera familia',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            await familyService.createFamily(nameCtrl.text.trim());
                            ref.invalidate(myFamiliesProvider);
                          } catch (e) {
                            setState(() => error = e.toString());
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: const Text('Crear y continuar'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ]
              ],
            );
          },
        ),
      ),
    );
  }
}
