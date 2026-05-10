import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/supabase.dart';

class PushService {
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initializing = false;

  Future<void> initialize() async {
    if (_initializing) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (sb.auth.currentUser == null) return;

    _initializing = true;
    try {
      final messaging = FirebaseMessaging.instance;

      // En Android 13+ e iOS esto muestra el permiso del sistema una sola vez.
      // No hay botón manual en la app: el registro queda automático.
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      await messaging.setAutoInitEnabled(true);

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }

      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        if (token.isNotEmpty) await _saveToken(token);
      });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _saveToken(String token) async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    await sb.from('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }
}
