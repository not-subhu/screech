import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/task.dart';
import '../models/habit.dart';
import '../models/reward.dart';
import '../models/wallet.dart';

class DbService {
  static Isar? _instance;

  static Future<Isar> open() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [TaskSchema, HabitSchema, RewardSchema, WalletSchema, LedgerEntrySchema],
      directory: dir.path,
      name: 'questify_db',
    );
    return _instance!;
  }

  static Isar get instance {
    if (_instance == null) {
      throw StateError('DbService.open() must be called before use.');
    }
    return _instance!;
  }
}
