import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/push_service.dart';
import '../models/module_models.dart';
import '../services/repositories.dart';

final authServiceProvider = Provider((ref) => AuthService());
final familyServiceProvider = Provider((ref) => FamilyService());
final repositoriesProvider = Provider((ref) => Repositories());
final pushServiceProvider = Provider((ref) => PushService());

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authState;
});

final myFamiliesProvider = FutureProvider((ref) async {
  final service = ref.watch(familyServiceProvider);
  await service.acceptPendingInvites();
  return service.myFamilies();
});

final currentFamilyIdProvider = FutureProvider((ref) async {
  return ref.watch(familyServiceProvider).currentFamilyId();
});

final pendingInviteCountProvider = FutureProvider((ref) async {
  return ref.watch(familyServiceProvider).pendingInviteCount();
});


final familyModulesProvider = FutureProvider<EnabledModules>((ref) async {
  final familyId = await ref.watch(currentFamilyIdProvider.future);
  if (familyId == null || familyId.isEmpty) {
    return EnabledModules({
      for (final definition in familyModuleDefinitions) definition.key: definition.defaultEnabled,
    });
  }
  final settings = await ref.watch(familyServiceProvider).moduleSettings(familyId);
  return EnabledModules({
    for (final definition in familyModuleDefinitions) definition.key: definition.defaultEnabled,
    for (final setting in settings) setting.key: setting.enabled,
  });
});
