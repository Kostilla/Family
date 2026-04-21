import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  int _index(String location) {
    if (location.startsWith('/shopping')) return 1;
    if (location.startsWith('/tasks')) return 2;
    if (location.startsWith('/menus')) return 3;
    if (location.startsWith('/calendar')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _index(location);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: child,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/shopping');
              break;
            case 2:
              context.go('/tasks');
              break;
            case 3:
              context.go('/menus');
              break;
            case 4:
              context.go('/calendar');
              break;
            case 5:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), label: 'Compra'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), label: 'Tareas'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), label: 'Menús'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
    );
  }
}
