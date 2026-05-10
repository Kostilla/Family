import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/module_models.dart';
import '../providers/app_providers.dart';
import 'pro_widgets.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int _index(String location, List<_NavItem> items) {
    final index = items.indexWhere((item) => location.startsWith(item.route));
    return index < 0 ? 0 : index;
  }

  List<_NavItem> _items(EnabledModules modules) {
    return [
      const _NavItem(
        route: '/home',
        icon: Icons.home_rounded,
        label: 'Inicio',
      ),
      ...modules.navModules.map(
        (module) => _NavItem(
          route: module.route,
          icon: module.icon,
          label: module.title,
        ),
      ),
      const _NavItem(
        route: '/settings',
        icon: Icons.tune_rounded,
        label: 'Ajustes',
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(familyModulesProvider);

    return modulesAsync.when(
      loading: () => Scaffold(
        body: PremiumBackground(
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => _buildShell(
        context,
        _items(EnabledModules({
          for (final definition in familyModuleDefinitions) definition.key: definition.defaultEnabled,
        })),
      ),
      data: (modules) => _buildShell(context, _items(modules)),
    );
  }

  Widget _buildShell(BuildContext context, List<_NavItem> items) {
    final selectedIndex = _index(location, items).clamp(0, items.length - 1);

    return Scaffold(
      extendBody: true,
      body: PremiumBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 88),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.35),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: (i) => context.go(items[i].route),
                destinations: [
                  for (final item in items)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.label,
  });
}
