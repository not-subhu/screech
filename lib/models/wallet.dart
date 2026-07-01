import 'package:isar/isar.dart';

part 'wallet.g.dart';

@collection
class Wallet {
  Id id = Isar.autoIncrement;

  int balance = 0;

  int totalEarnedLifetime = 0;

  int totalSpentLifetime = 0;
}

enum LedgerType { earned, spent }

@collection
class LedgerEntry {
  Id id = Isar.autoIncrement;

  @enumerated
  LedgerType type = LedgerType.earned;

  int amount = 0;

  late String reason; // e.g. "Completed: Finish Physics HW" or "Redeemed: 30 min gaming"

  DateTime timestamp = DateTime.now();
}
