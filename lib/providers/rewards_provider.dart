import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/reward.dart';
import '../services/db_service.dart';
import 'wallet_provider.dart';

class RewardsNotifier extends StateNotifier<List<Reward>> {
  RewardsNotifier(this.ref) : super([]) {
    _init();
  }

  final Ref ref;
  final Isar _isar = DbService.instance;

  Future<void> _init() async {
    final existing = await _isar.rewards.where().findAll();
    if (existing.isEmpty) {
      await _seedDefaults();
    }
    await _load();
  }

  Future<void> _seedDefaults() async {
    final defaults = [
      Reward()
        ..title = '15 min phone break'
        ..description = 'Guilt-free scrolling, timer optional.'
        ..cost = 30
        ..emoji = '📱'
        ..isCustom = false,
      Reward()
        ..title = 'Episode of your current anime'
        ..description = 'One episode, no cliffhanger excuses.'
        ..cost = 60
        ..emoji = '🍥'
        ..isCustom = false,
      Reward()
        ..title = 'Favorite snack'
        ..description = 'You earned it.'
        ..cost = 40
        ..emoji = '🍡'
        ..isCustom = false,
      Reward()
        ..title = '30 min gaming session'
        ..description = 'Minecraft, etc.'
        ..cost = 80
        ..emoji = '🎮'
        ..isCustom = false,
      Reward()
        ..title = 'Sleep in 30 extra minutes'
        ..description = 'Redeemable the next morning.'
        ..cost = 100
        ..emoji = '😴'
        ..isCustom = false,
    ];
    await _isar.writeTxn(() async {
      for (final r in defaults) {
        await _isar.rewards.put(r);
      }
    });
  }

  Future<void> _load() async {
    final rewards = await _isar.rewards.where().sortByCostDesc().findAll();
    state = rewards;
  }

  Future<void> addReward({
    required String title,
    String? description,
    required int cost,
    String emoji = '🎁',
  }) async {
    final reward = Reward()
      ..title = title
      ..description = description
      ..cost = cost
      ..emoji = emoji
      ..isCustom = true;
    await _isar.writeTxn(() async {
      await _isar.rewards.put(reward);
    });
    await _load();
  }

  Future<void> deleteReward(Reward reward) async {
    await _isar.writeTxn(() async {
      await _isar.rewards.delete(reward.id);
    });
    await _load();
  }

  /// Attempts to redeem a reward. Returns true on success (sufficient coins).
  Future<bool> redeem(Reward reward) async {
    final success = await ref.read(walletProvider.notifier).spend(
          reward.cost,
          'Redeemed: ${reward.title}',
        );
    if (success) {
      reward.timesRedeemed += 1;
      await _isar.writeTxn(() async {
        await _isar.rewards.put(reward);
      });
      await _load();
    }
    return success;
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, List<Reward>>((ref) {
  return RewardsNotifier(ref);
});
