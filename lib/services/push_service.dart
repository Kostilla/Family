import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../core/supabase.dart';

class PushService {
  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
  }

  Future<void> _saveToken(String token) async {
    final user = sb.auth.currentUser;
    if (user == null) return;

    await sb.from('device_tokens').upsert({
      'user_id': user.id,
      'token': token,
      'platform': Platform.isIOS ? 'ios' : 'android',
    }, onConflict: 'token');
  }
}
