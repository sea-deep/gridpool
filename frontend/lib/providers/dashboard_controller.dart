import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/providers/auth_controller.dart';

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, List<Pool>>(() {
      return DashboardController();
    });

class DashboardController extends AsyncNotifier<List<Pool>> {
  PoolRepository get _repository => ref.read(poolRepositoryProvider);

  @override
  Future<List<Pool>> build() async {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    if (user == null) return [];

    return _repository.fetchPoolsForUser(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.user;
      if (user == null) {
        state = const AsyncData([]);
        return;
      }

      final pools = await _repository.fetchPoolsForUser(user.id);
      state = AsyncData(pools);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createPool({
    required String name,
    required String description,
    required String? upiId,
    required String frequency,
    int? customInterval,
    double expectedContribution = 0.0,
  }) async {
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.user;
      if (user == null) {
        throw Exception('Please log in to create a pool');
      }

      final newPool = await _repository.createPool(
        name: name,
        description: description,
        ownerId: user.id,
        ownerName: user.name,
        ownerEmail: user.email,
        ownerAvatarUrl: user.avatarUrl,
        upiId: upiId,
        frequency: frequency,
        customInterval: customInterval,
        expectedContribution: expectedContribution,
      );
      if (state.hasValue) {
        state = AsyncData([...state.value!, newPool]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinPool(String inviteCode) async {
    try {
      final authState = ref.read(authControllerProvider);
      final user = authState.user;
      if (user == null) {
        throw Exception('Please log in to join a pool');
      }

      await _repository.submitJoinRequest(
        inviteCode: inviteCode,
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userAvatarUrl: user.avatarUrl,
      );
    } catch (e) {
      rethrow;
    }
  }
}
