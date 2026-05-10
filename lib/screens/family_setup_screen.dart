import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../services/family_service.dart';
import '../widgets/pro_widgets.dart';

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
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _afterChange() async {
    ref.invalidate(myFamiliesProvider);
    ref.invalidate(currentFamilyIdProvider);
    ref.invalidate(pendingInviteCountProvider);
    await ref.read(pushServiceProvider).initialize();
    if (mounted) context.go('/home');
  }

  Widget _familyTile(FamilySummary f, String? currentFamilyId, FamilyService familyService) {
    final selected = f.id == currentFamilyId;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(selected ? Icons.check : Icons.family_restroom),
        ),
        title: Text(f.name),
        subtitle: Text('Rol: ${f.role}'),
        trailing: selected ? const Icon(Icons.check_circle) : const Icon(Icons.chevron_right),
        onTap: () async {
          setState(() {
            busy = true;
            error = null;
          });
          try {
            await familyService.switchCurrentFamily(f.id);
            await _afterChange();
          } catch (e) {
            setState(() => error = e.toString());
          } finally {
            if (mounted) setState(() => busy = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final pendingAsync = ref.watch(pendingInviteCountProvider);
    final familyService = ref.watch(familyServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tus familias')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: currentFamilyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (currentFamilyId) => familiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (families) {
              return ListView(
                children: [
                  const ProHeader(
                    icon: Icons.family_restroom,
                    title: 'Familia Pro',
                    subtitle: 'Crea una familia, únete con invitación o cambia la activa.',
                  ),
                  const SizedBox(height: 12),
                  pendingAsync.when(
                    data: (count) => SectionCard(
                      icon: Icons.mail_outline,
                      title: 'Invitaciones pendientes',
                      subtitle: count == 0
                          ? 'No tienes invitaciones pendientes.'
                          : 'Pendientes: $count',
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () async {
                                  setState(() {
                                    busy = true;
                                    error = null;
                                  });
                                  try {
                                    await familyService.acceptPendingInvites();
                                    ref.invalidate(myFamiliesProvider);
                                    ref.invalidate(currentFamilyIdProvider);
                                    ref.invalidate(pendingInviteCountProvider);
                                  } catch (e) {
                                    setState(() => error = e.toString());
                                  } finally {
                                    if (mounted) setState(() => busy = false);
                                  }
                                },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Revisar invitaciones'),
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  if (families.isNotEmpty) ...[
                    SectionCard(
                      icon: Icons.swap_horiz,
                      title: 'Selecciona familia',
                      subtitle: 'La familia activa se usará en toda la app.',
                      child: Column(
                        children: families
                            .map((f) => _familyTile(f, currentFamilyId, familyService))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SectionCard(
                    icon: Icons.group_add_outlined,
                    title: families.isEmpty ? 'Crea tu primera familia' : 'Crear nueva familia',
                    subtitle: 'Después podrás invitar a otras personas desde Ajustes.',
                    child: Column(
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la familia',
                            hintText: 'Ej. Familia Costa Giménez',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () async {
                                    setState(() {
                                      busy = true;
                                      error = null;
                                    });
                                    try {
                                      await familyService.createFamily(nameCtrl.text.trim());
                                      nameCtrl.clear();
                                      await _afterChange();
                                    } catch (e) {
                                      setState(() => error = e.toString());
                                    } finally {
                                      if (mounted) setState(() => busy = false);
                                    }
                                  },
                            icon: const Icon(Icons.add),
                            label: Text(families.isEmpty ? 'Crear y continuar' : 'Crear familia'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
