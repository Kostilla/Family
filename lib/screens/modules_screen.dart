import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/module_models.dart';
import '../providers/app_providers.dart';
import '../widgets/pro_widgets.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyIdAsync = ref.watch(currentFamilyIdProvider);
    final modulesAsync = ref.watch(familyModulesProvider);
    final service = ref.watch(familyServiceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const ProHeader(
          icon: Icons.dashboard_customize_rounded,
          title: 'Módulos',
          subtitle: 'Activa solo lo que quieres usar en esta familia',
        ),
        const SizedBox(height: 12),
        familyIdAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (familyId) {
            if (familyId == null || familyId.isEmpty) {
              return const RequireFamily();
            }
            return modulesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => SectionCard(
                icon: Icons.error_outline,
                title: 'No se pudieron cargar módulos',
                subtitle: 'Comprueba que has ejecutado el SQL de módulos en Supabase.',
                child: Text(e.toString()),
              ),
              data: (modules) {
                return Column(
                  children: [
                    SectionCard(
                      icon: Icons.tune_rounded,
                      title: 'Configuración por familia',
                      subtitle: 'Los cambios afectan a todos los miembros de esta familia.',
                      child: Column(
                        children: [
                          for (final definition in familyModuleDefinitions)
                            _ModuleSwitch(
                              definition: definition,
                              enabled: modules.isEnabled(definition.key),
                              onChanged: (value) async {
                                await service.setModuleEnabled(
                                  familyId: familyId,
                                  moduleKey: definition.key,
                                  enabled: value,
                                );
                                ref.invalidate(familyModulesProvider);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const EmptyState(
                      icon: Icons.info_outline_rounded,
                      title: 'Arquitectura modular activa',
                      message: 'La barra inferior y el Inicio se adaptan automáticamente a los módulos activos.',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ModuleSwitch extends StatefulWidget {
  const _ModuleSwitch({
    required this.definition,
    required this.enabled,
    required this.onChanged,
  });

  final FamilyModuleDefinition definition;
  final bool enabled;
  final Future<void> Function(bool value) onChanged;

  @override
  State<_ModuleSwitch> createState() => _ModuleSwitchState();
}

class _ModuleSwitchState extends State<_ModuleSwitch> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(widget.definition.icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(widget.definition.title),
      subtitle: Text(widget.definition.subtitle),
      trailing: saving
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch.adaptive(
              value: widget.enabled,
              onChanged: (value) async {
                setState(() => saving = true);
                try {
                  await widget.onChanged(value);
                } finally {
                  if (mounted) setState(() => saving = false);
                }
              },
            ),
    );
  }
}
