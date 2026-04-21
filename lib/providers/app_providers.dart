import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/push_service.dart';
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
