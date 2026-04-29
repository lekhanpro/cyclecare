import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/partner_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final partnerServiceProvider = Provider<PartnerService>((ref) {
  return PartnerService();
});

final myPartnerLinkProvider = StreamProvider<PartnerLink?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(partnerServiceProvider).watchMyLink(user.uid);
});

final partnerLinkForMeProvider = StreamProvider<PartnerLink?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(partnerServiceProvider).watchPartnerLink(user.uid);
});

final partnerSharedDataProvider = StreamProvider.family<SharedCycleData?, String>(
  (ref, ownerUid) {
    return ref.watch(partnerServiceProvider).watchSharedData(ownerUid);
  },
);
