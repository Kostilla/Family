import '../core/supabase.dart';
import '../models/app_models.dart';

class FamilyService {
  Future<List<FamilySummary>> myFamilies() async {
    final rows = await sb.rpc('my_families');
    return (rows as List)
        .map((e) => FamilySummary.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createFamily(String name) async {
    await sb.rpc('create_family', params: {'p_name': name});
  }

  Future<void> switchCurrentFamily(String familyId) async {
    await sb.rpc('set_current_family', params: {'p_family_id': familyId});
  }

  Future<void> inviteMember({
    required String familyId,
    required String email,
    required String role,
  }) async {
    await sb.from('family_invites').insert({
      'family_id': familyId,
      'email': email.toLowerCase().trim(),
      'role': role,
    });
  }

  Future<String?> currentFamilyId() async {
    final row = await sb
        .from('profiles')
        .select('current_family_id')
        .eq('id', sb.auth.currentUser!.id)
        .maybeSingle();
    return row?['current_family_id'] as String?;
  }

  Future<void> acceptPendingInvites() async {
    await sb.rpc('accept_pending_family_invites');
  }
}
