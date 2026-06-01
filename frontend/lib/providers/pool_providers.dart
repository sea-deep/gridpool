import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/models/pool_member.dart';
import 'package:frontend/models/join_request.dart';
import 'package:frontend/models/ledger_entry.dart';
import 'package:frontend/models/payment_request.dart';

final poolMembersProvider = StreamProvider.family<List<PoolMember>, String>((
  ref,
  poolId,
) {
  return ref.watch(poolRepositoryProvider).watchMembers(poolId);
});

final joinRequestsProvider = StreamProvider.family<List<JoinRequest>, String>((
  ref,
  poolId,
) {
  return ref.watch(poolRepositoryProvider).watchJoinRequests(poolId);
});

final poolRoleProvider = StreamProvider.family<PoolRole?, String>((
  ref,
  poolId,
) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user;
  if (user == null) {
    return Stream<PoolRole?>.value(null);
  }

  return ref.watch(poolRepositoryProvider).watchMemberRole(poolId, user.id);
});

final ledgerProvider = StreamProvider.family<List<LedgerEntry>, String>((
  ref,
  poolId,
) {
  return ref.watch(poolRepositoryProvider).watchLedger(poolId);
});



/// Cross-pool activity feed for the current user
final activityFeedProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.user == null) {
    return Stream.value([]);
  }
  return ref.watch(poolRepositoryProvider).watchActivity();
});


final paymentRequestsProvider = StreamProvider.family<List<PaymentRequest>, String>((ref, poolId) {
  final repo = ref.watch(poolRepositoryProvider);
  return repo.watchPaymentRequests(poolId);
});

