import 'package:isar/isar.dart';

part 'reward.g.dart';

@collection
class Reward {
  Id id = Isar.autoIncrement;

  late String title;

  String? description;

  int cost = 50;

  /// Emoji or icon-key used in the shop card (keeps this asset-light).
  String emoji = '🎁';

  bool isCustom = true;

  int timesRedeemed = 0;

  DateTime createdAt = DateTime.now();
}
