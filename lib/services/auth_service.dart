import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase.dart';

class AuthService {
  Session? get session => sb.auth.currentSession;
  User? get user => sb.auth.currentUser;

  Stream<AuthState> get authState => sb.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await sb.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String displayName) async {
    await sb.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<void> signOut() => sb.auth.signOut();
}
