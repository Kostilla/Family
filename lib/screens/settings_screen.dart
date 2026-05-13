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
  final searchCtrl = TextEditingController();
  String role = 'adult';
  bool inviting = false;
  String query = '';

  @override
  void dispose() {
    inviteCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  FamilySummary? _pickCurrentFamily(List<FamilySummary> families, String? currentFamilyId) {
    for (final family in families) {
      if (family.id == currentFamilyId) return family;
    }
    return families.isEmpty ? null : families.first;
  }

  bool _matches(String text) {
    if (query.trim().isEmpty) return true;
    return text.toLowerCase().contains(query.trim().toLowerCase());
  }

  void _comingSoon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
          icon: Icons.settings_rounded,
          title: 'Ajustes',
          subtitle: 'Personaliza tu cuenta, familia, módulos y preferencias',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchCtrl,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Buscar ajuste...',
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      searchCtrl.clear();
                      setState(() => query = '');
                    },
                  ),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 14),
        if (_matches('perfil nombre avatar imagen cuenta usuario')) ...[
          const _SettingsCategoryTitle('Cuenta'),
          const _ProfileSection(),
          const SizedBox(height: 12),
        ],
        if (_matches('familia miembros invitaciones cambiar crear gestionar')) ...[
          const _SettingsCategoryTitle('Familia'),
          _SettingsGroup(
            icon: Icons.family_restroom_rounded,
            title: 'Familia y miembros',
            subtitle: 'Gestiona la familia activa, miembros e invitaciones',
            children: [
              _SettingsTile(
                icon: Icons.swap_horiz_rounded,
                title: 'Gestionar familias',
                subtitle: 'Cambiar familia activa, crear otra o revisar invitaciones',
                onTap: () => context.go('/family-setup'),
              ),
              currentFamilyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => _InlineError(text: 'Error cargando familia: $e'),
                data: (currentFamilyId) => familiesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => _InlineError(text: 'Error cargando familias: $e'),
                  data: (families) {
                    final current = _pickCurrentFamily(families, currentFamilyId);
                    if (current == null) {
                      return const _InlineHint(
                        icon: Icons.info_outline_rounded,
                        text: 'Crea o selecciona una familia para poder invitar miembros.',
                      );
                    }
                    return _InviteMembersPanel(
                      familyName: current.name,
                      inviteCtrl: inviteCtrl,
                      role: role,
                      inviting: inviting,
                      onRoleChanged: (value) => setState(() => role = value ?? 'adult'),
                      onInvite: () async {
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
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_matches('modulos personalizacion secciones activar desactivar')) ...[
          const _SettingsCategoryTitle('Personalización'),
          _SettingsGroup(
            icon: Icons.dashboard_customize_rounded,
            title: 'Módulos y secciones',
            subtitle: 'Elige qué aparece en la app para esta familia',
            children: [
              _SettingsTile(
                icon: Icons.tune_rounded,
                title: 'Configurar módulos',
                subtitle: 'Activa o desactiva Compra, Tareas, Agenda, IA familiar y más',
                onTap: () => context.go('/modules'),
              ),
              _SettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: 'IA familiar',
                subtitle: 'Resumen diario y sugerencias inteligentes',
                onTap: () => _comingSoon('La IA familiar se configura desde su módulo y desde el Inicio.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_matches('calendario agenda categorias colores eventos')) ...[
          const _SettingsCategoryTitle('Calendario'),
          _SettingsGroup(
            icon: Icons.calendar_month_rounded,
            title: 'Calendario y eventos',
            subtitle: 'Colores, categorías y organización visual',
            children: [
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Categorías del calendario',
                subtitle: 'Crea, edita y colorea categorías de eventos',
                onTap: () => context.go('/calendar-categories'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_matches('notificaciones push avisos recordatorios resumen diario')) ...[
          const _SettingsCategoryTitle('Notificaciones'),
          _SettingsGroup(
            icon: Icons.notifications_active_outlined,
            title: 'Avisos y recordatorios',
            subtitle: 'Push, recordatorios y resúmenes familiares',
            children: [
              _SettingsTile(
                icon: Icons.phone_android_rounded,
                title: 'Dispositivo registrado automáticamente',
                subtitle: 'Las notificaciones se activan al iniciar sesión en móvil',
                onTap: () => _comingSoon('El registro push es automático. No hace falta hacer nada manualmente.'),
              ),
              _SettingsTile(
                icon: Icons.wb_sunny_outlined,
                title: 'Resumen diario',
                subtitle: 'Preparado para recibir un resumen de agenda, tareas y compra',
                onTap: () => _comingSoon('El resumen diario se conectará cuando termines la configuración de Firebase/FCM.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_matches('apariencia tema claro oscuro diseño compacto colores')) ...[
          const _SettingsCategoryTitle('Apariencia'),
          _SettingsGroup(
            icon: Icons.dark_mode_outlined,
            title: 'Aspecto de la app',
            subtitle: 'Diseño, tema y densidad visual',
            children: [
              _SettingsTile(
                icon: Icons.contrast_rounded,
                title: 'Tema claro / oscuro',
                subtitle: 'Actualmente sigue el tema del sistema',
                onTap: () => _comingSoon('La app usa el tema del sistema. Más adelante se puede guardar preferencia por usuario.'),
              ),
              _SettingsTile(
                icon: Icons.view_agenda_outlined,
                title: 'Vista compacta',
                subtitle: 'Opción preparada para una interfaz más densa',
                onTap: () => _comingSoon('La vista compacta se puede añadir como preferencia de usuario.'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_matches('sistema sesion cerrar datos version soporte')) ...[
          const _SettingsCategoryTitle('Sistema'),
          _SettingsGroup(
            icon: Icons.shield_outlined,
            title: 'Cuenta y seguridad',
            subtitle: 'Sesión, datos y estado de la aplicación',
            children: [
              const _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'Versión',
                subtitle: 'Family Pro · desarrollo',
              ),
              _SettingsTile(
                icon: Icons.logout_rounded,
                title: 'Cerrar sesión',
                subtitle: 'Salir de esta cuenta en este dispositivo',
                destructive: true,
                onTap: () => auth.signOut(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SettingsCategoryTitle extends StatelessWidget {
  const _SettingsCategoryTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}


class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _CollapsibleSettingsCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.45)),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _CollapsibleSettingsCard extends StatefulWidget {
  const _CollapsibleSettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleSettingsCard> createState() => _CollapsibleSettingsCardState();
}

class _CollapsibleSettingsCardState extends State<_CollapsibleSettingsCard> {
  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withOpacity(.72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: scheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: widget.child,
            ),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _InviteMembersPanel extends StatelessWidget {
  const _InviteMembersPanel({
    required this.familyName,
    required this.inviteCtrl,
    required this.role,
    required this.inviting,
    required this.onRoleChanged,
    required this.onInvite,
  });

  final String familyName;
  final TextEditingController inviteCtrl;
  final String role;
  final bool inviting;
  final ValueChanged<String?> onRoleChanged;
  final Future<void> Function() onInvite;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      leading: const Icon(Icons.person_add_alt_1_outlined),
      title: const Text('Invitar miembro'),
      subtitle: Text('Familia activa: $familyName'),
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
          onChanged: onRoleChanged,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: inviting ? null : onInvite,
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
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}


class _ProfileSection extends ConsumerStatefulWidget {
  const _ProfileSection();

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  final nameCtrl = TextEditingController();
  bool saving = false;
  bool initialized = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => saving = true);
    try {
      await ref.read(repositoriesProvider).updateCurrentProfileName(name);
      ref.invalidate(currentProfileProvider);
      final familyId = await ref.read(currentFamilyIdProvider.future);
      if (familyId != null) ref.invalidate(familyProfilesProvider(familyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar perfil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _changeAvatar() async {
    setState(() => saving = true);
    try {
      await ref.read(repositoriesProvider).pickAndUploadCurrentAvatar();
      ref.invalidate(currentProfileProvider);
      final familyId = await ref.read(currentFamilyIdProvider.future);
      if (familyId != null) ref.invalidate(familyProfilesProvider(familyId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    return profileAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => _CollapsibleSettingsCard(
        icon: Icons.person_outline,
        title: 'Mi perfil',
        subtitle: 'No se pudo cargar el perfil',
        child: Text('Error: $e'),
      ),
      data: (profile) {
        if (profile != null && !initialized) {
          nameCtrl.text = profile.displayName;
          initialized = true;
        }
        final initials = profile?.initials ?? 'U';
        return _CollapsibleSettingsCard(
          icon: Icons.account_circle_outlined,
          title: 'Mi perfil',
          subtitle: 'Este nombre e imagen se verán en chat y acciones familiares',
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(
                    initials: initials,
                    avatarPath: profile?.avatarPath,
                    radius: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre visible',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : _changeAvatar,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Cambiar imagen'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: saving ? null : _saveName,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Guardando...' : 'Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
