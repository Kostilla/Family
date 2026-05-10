import 'package:flutter/material.dart';

class FamilyModuleSetting {
  final String key;
  final bool enabled;
  final int sortOrder;

  const FamilyModuleSetting({
    required this.key,
    required this.enabled,
    required this.sortOrder,
  });

  factory FamilyModuleSetting.fromMap(Map<String, dynamic> map) {
    return FamilyModuleSetting(
      key: (map['module_key'] ?? map['key'] ?? '').toString(),
      enabled: (map['enabled'] as bool?) ?? true,
      sortOrder: (map['sort_order'] as int?) ?? 999,
    );
  }
}

class FamilyModuleDefinition {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool showInNav;
  final bool defaultEnabled;
  final int sortOrder;

  const FamilyModuleDefinition({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.showInNav,
    required this.defaultEnabled,
    required this.sortOrder,
  });
}

const familyModuleDefinitions = <FamilyModuleDefinition>[
  FamilyModuleDefinition(
    key: 'shopping',
    title: 'Compra',
    subtitle: 'Lista compartida',
    icon: Icons.shopping_bag_rounded,
    route: '/shopping',
    showInNav: true,
    defaultEnabled: true,
    sortOrder: 10,
  ),
  FamilyModuleDefinition(
    key: 'tasks',
    title: 'Tareas',
    subtitle: 'Organización familiar',
    icon: Icons.task_alt_rounded,
    route: '/tasks',
    showInNav: true,
    defaultEnabled: true,
    sortOrder: 20,
  ),
  FamilyModuleDefinition(
    key: 'menus',
    title: 'Menús',
    subtitle: 'Comidas de la semana',
    icon: Icons.restaurant_rounded,
    route: '/menus',
    showInNav: true,
    defaultEnabled: true,
    sortOrder: 30,
  ),
  FamilyModuleDefinition(
    key: 'calendar',
    title: 'Agenda',
    subtitle: 'Eventos y recordatorios',
    icon: Icons.calendar_month_rounded,
    route: '/calendar',
    showInNav: true,
    defaultEnabled: true,
    sortOrder: 40,
  ),
  FamilyModuleDefinition(
    key: 'chat',
    title: 'Chat',
    subtitle: 'Mensajes familiares en Inicio',
    icon: Icons.chat_bubble_rounded,
    route: '/home',
    showInNav: false,
    defaultEnabled: true,
    sortOrder: 50,
  ),
  FamilyModuleDefinition(
    key: 'attachments',
    title: 'Adjuntos',
    subtitle: 'Fotos y archivos',
    icon: Icons.attach_file_rounded,
    route: '/settings',
    showInNav: false,
    defaultEnabled: true,
    sortOrder: 60,
  ),
];

Map<String, FamilyModuleDefinition> get familyModuleDefinitionByKey => {
      for (final definition in familyModuleDefinitions) definition.key: definition,
    };

class EnabledModules {
  final Map<String, bool> values;

  const EnabledModules(this.values);

  bool isEnabled(String key) => values[key] ?? _defaultValue(key);

  static bool _defaultValue(String key) {
    final definition = familyModuleDefinitionByKey[key];
    return definition?.defaultEnabled ?? true;
  }

  List<FamilyModuleDefinition> get navModules {
    final items = familyModuleDefinitions
        .where((definition) => definition.showInNav && isEnabled(definition.key))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }
}
