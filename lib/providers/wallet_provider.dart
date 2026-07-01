import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../models/wallet.dart';
import '../services/db_service.dart';

class WalletNotifier extends StateNotifier<Wallet> {
  WalletNotifier() : super(Wallet()) {
    _load();
  }

  final Isar _isar = DbService.instance;

  Future<void> _load() async {
    var wallet = await _isar.wallets.where().findFirst();
    if (wallet == null) {
      wallet = Wallet();
      await _isar.writeTxn(() async {
        await _isar.wallets.put(wallet!);
      });
    }
    state = wallet;
  }

  Future<void> earn(int amount, String reason) async {
    if (amount <= 0) return;
    final updated = Wallet()
      ..id = state.id
      ..balance = state.balance + amount
      ..totalEarnedLifetime = state.totalEarnedLifetime + amount
      ..totalSpentLifetime = state.totalSpentLifetime;

    await _isar.writeTxn(() async {
      await _isar.wallets.put(updated);
      await _isar.ledgerEntrys.put(
        LedgerEntry()
          ..type = LedgerType.earned
          ..amount = amount
          ..reason = reason,
      );
    });
    state = updated;
  }

  /// Returns true if the spend succeeded (sufficient balance), false otherwise.
  Future<bool> spend(int amount, String reason) async {
    if (amount <= 0 || state.balance < amount) return false;
    final updated = Wallet()
      ..id = state.id
      ..balance = state.balance - amount
      ..totalEarnedLifetime = state.totalEarnedLifetime
      ..totalSpentLifetime = state.totalSpentLifetime + amount;

    await _isar.writeTxn(() async {
      await _isar.wallets.put(updated);
      await _isar.ledgerEntrys.put(
        LedgerEntry()
          ..type = LedgerType.spent
          ..amount = amount
          ..reason = reason,
      );
    });
    state = updated;
    return true;
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, Wallet>((ref) {
  return WalletNotifier();
});

final ledgerHistoryProvider = FutureProvider<List<LedgerEntry>>((ref) async {
  ref.watch(walletProvider); // refresh when wallet changes
  final isar = DbService.instance;
  return isar.ledgerEntrys.where().sortByTimestampDesc().limit(50).findAll();
});
