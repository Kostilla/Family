import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/supabase.dart';
import 'core/theme.dart';
import 'providers/app_providers.dart';

class FamilyApp extends ConsumerStatefulWidget {
  const FamilyApp({super.key});

  @override
  ConsumerState<FamilyApp> createState() => _FamilyAppState();
}

class _FamilyAppState extends ConsumerState<FamilyApp> {
  bool _bootstrappedPush = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPushIfLoggedIn());
  }

  Future<void> _registerPushIfLoggedIn() async {
    if (_bootstrappedPush) return;
    if (sb.auth.currentUser == null) return;
    _bootstrappedPush = true;
    await ref.read(pushServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, __) {
      if (sb.auth.currentUser != null) {
        ref.read(pushServiceProvider).initialize();
      } else {
        _bootstrappedPush = false;
      }
    });

    return MaterialApp.router(
      title: 'Familia Pro',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
