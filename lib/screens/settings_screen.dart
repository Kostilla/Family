import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final inviteCtrl = TextEditingController();
  String role = 'adult';
  bool inviting = false;

  @override
  void dispose() {
    inviteCtrl.dispose();
    super.dispose();
  }

  FamilySummary? _pickCurrentFamily(List<FamilySummary> families, String? currentFamilyId) {
    for (final family in families) {
      if (family.id == currentFamilyId) return family;
    }
    return families.isEmpty ? null : families.first;
  }

  @override
  Widget build(BuildContext context) {
    final familiesAsync = ref.watch(myFamiliesProvider);
    final currentFamilyAsync = ref.watch(currentFamilyIdProvider);
    final auth = ref.watch(authServiceProvider);
    final service = ref.watch(familyServiceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ProHeader(
          icon: Icons.settings_outlined,
          title: 'Ajustes',
          subtitle: 'Familias, invitaciones y cuenta',
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.family_restroom,
          title: 'Familias',
          subtitle: 'Cambia la familia activa o crea otra',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/family-setup'),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Gestionar familias'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.dashboard_customize_rounded,
          title: 'Módulos',
          subtitle: 'Elige qué secciones aparecen para esta familia',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/modules'),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Configurar módulos'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.category_outlined,
          title: 'Categorías del calendario',
          subtitle: 'Crea y edita los colores de eventos',
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go('/calendar-categories'),
              icon: const Icon(Icons.palette_outlined),
              label: const Text('Gestionar categorías'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        currentFamilyAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (currentFamilyId) => familiesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (families) {
              final current = _pickCurrentFamily(families, currentFamilyId);
              if (current == null) {
                return const RequireFamily();
              }

              return SectionCard(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Invitar miembros',
                subtitle: 'Familia activa: ${current.name}',
                child: Column(
                  children: [
                    TextField(
                      controller: inviteCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        labelText: 'Email de la persona',
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(value: 'adult', child: Text('Adulto')),
                        DropdownMenuItem(value: 'child', child: Text('Niño/a')),
                      ],
                      onChanged: (v) => setState(() => role = v ?? 'adult'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: inviting
                            ? null
                            : () async {
                                final email = inviteCtrl.text.trim();
                                if (email.isEmpty) return;
                                setState(() => inviting = true);
                                try {
                                  await service.inviteMember(
                                    familyId: current.id,
                                    email: email,
                                    role: role,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Invitación creada')),
                                    );
                                  }
                                  inviteCtrl.clear();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al invitar: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => inviting = false);
                                }
                              },
                        icon: const Icon(Icons.send_outlined),
                        label: Text(inviting ? 'Enviando...' : 'Crear invitación'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'La otra persona debe registrarse con ese email y pulsar “Revisar invitaciones”.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => auth.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    );
  }
}
