import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/calendar_screen.dart';
import '../screens/family_setup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/menus_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shopping_screen.dart';
import '../screens/tasks_screen.dart';
import '../widgets/scaffold_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthRefreshNotifier extends ChangeNotifier {
  AuthRefreshNotifier(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  refreshListenable: AuthRefreshNotifier(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  initialLocation: '/home',
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final loggingIn = state.matchedLocation == '/login';

    if (user == null) {
      return loggingIn ? null : '/login';
    }

    if (loggingIn) return '/family-setup';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/family-setup',
      builder: (_, __) => const FamilySetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/shopping', builder: (_, __) => const ShoppingScreen()),
        GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
        GoRoute(path: '/menus', builder: (_, __) => const MenusScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
