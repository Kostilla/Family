import '../core/supabase.dart';
import '../models/app_models.dart';
import '../models/module_models.dart';

class FamilyService {
  Future<List<FamilySummary>> myFamilies() async {
    final rows = await sb.rpc('my_families');
    return (rows as List)
        .map((e) => FamilySummary.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<String?> createFamily(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final result = await sb.rpc('create_family', params: {'p_name': trimmed});
    final familyId = result?.toString();
    if (familyId != null && familyId.isNotEmpty) {
      await switchCurrentFamily(familyId);
    }
    return familyId;
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
    final current = row?['current_family_id']?.toString();
    if (current != null && current.isNotEmpty) return current;
    final families = await myFamilies();
    if (families.isEmpty) return null;
    final first = families.first.id;
    await switchCurrentFamily(first);
    return first;
  }

  Future<int> pendingInviteCount() async {
    final email = sb.auth.currentUser?.email?.toLowerCase().trim();
    if (email == null || email.isEmpty) return 0;
    final rows = await sb
        .from('family_invites')
        .select('id')
        .eq('email', email);
    return (rows as List).length;
  }

  Future<void> acceptPendingInvites() async {
    await sb.rpc('accept_pending_family_invites');
  }

  Future<List<FamilyModuleSetting>> moduleSettings(String familyId) async {
    try {
      final rows = await sb
          .from('family_modules')
          .select('module_key, enabled, sort_order')
          .eq('family_id', familyId)
          .order('sort_order');
      return (rows as List)
          .map((e) => FamilyModuleSetting.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [
        for (final definition in familyModuleDefinitions)
          FamilyModuleSetting(
            key: definition.key,
            enabled: definition.defaultEnabled,
            sortOrder: definition.sortOrder,
          ),
      ];
    }
  }

  Future<void> setModuleEnabled({
    required String familyId,
    required String moduleKey,
    required bool enabled,
  }) async {
    final definition = familyModuleDefinitionByKey[moduleKey];
    final sortOrder = definition?.sortOrder ?? 999;
    try {
      await sb.from('family_modules').upsert({
        'family_id': familyId,
        'module_key': moduleKey,
        'enabled': enabled,
        'sort_order': sortOrder,
      }, onConflict: 'family_id,module_key');
    } catch (_) {
      rethrow;
    }
  }

}
