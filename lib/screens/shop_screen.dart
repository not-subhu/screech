import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/reward.dart';
import '../providers/rewards_provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A2566), Color(0xFF2D1B4E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.coinGold.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coinGold.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.coinGlow,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coinGold.withOpacity(0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('✦',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Balance',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        Text(
                          '${wallet.balance} coins',
                          style: const TextStyle(
                            color: AppColors.coinGold,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${wallet.totalEarnedLifetime}',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const Text('earned total',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${wallet.totalSpentLifetime}',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const Text('spent total',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('REWARDS',
                      style: Theme.of(context).textTheme.labelSmall),
                  TextButton.icon(
                    onPressed: () => _showAddReward(context, ref),
                    icon: const Icon(Icons.add, size: 16, color: AppColors.sakura),
                    label: const Text('Add',
                        style: TextStyle(
                            color: AppColors.sakura,
                            fontWeight: FontWeight.w700)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _RewardCard(
                  reward: rewards[i],
                  canAfford: wallet.balance >= rewards[i].cost,
                  onRedeem: () => _redeem(context, ref, rewards[i]),
                ).animate().fadeIn(delay: (i * 50).ms).scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1, 1),
                      duration: 280.ms,
                      curve: Curves.easeOut,
                    ),
                childCount: rewards.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _redeem(
      BuildContext context, WidgetRef ref, Reward reward) async {
    final wallet = ref.read(walletProvider);
    if (wallet.balance < reward.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not enough coins! Need ${reward.cost - wallet.balance} more (；一_一)'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Redeem ${reward.emoji} ${reward.title}?',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('This will cost ${reward.cost} coins.',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coinGold,
                foregroundColor: Colors.white),
            child: const Text('Redeem ✦'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await ref.read(rewardsProvider.notifier).redeem(reward);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Enjoy your reward! ${reward.emoji}  (ﾉ◕ヮ◕)ﾉ*:･ﾟ✧'
                : 'Not enough coins! (；一_一)'),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddReward(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: '50');
    String emoji = '🎁';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Custom Reward',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final emojis = [
                          '🎁', '🍡', '📱', '🎮', '😴', '🍕', '🎵',
                          '🎬', '🛁', '☕', '🍫', '🎯', '🧸', '🌸'
                        ];
                        final picked = await showDialog<String>(
                          context: ctx,
                          builder: (_) => SimpleDialog(
                            backgroundColor: AppColors.surface,
                            children: [
                              Wrap(
                                children: emojis
                                    .map((e) => InkWell(
                                          onTap: () =>
                                              Navigator.pop(ctx, e),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text(e,
                                                style: const TextStyle(
                                                    fontSize: 28)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => emoji = picked);
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.bgDeep,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Center(
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: titleCtrl,
                        autofocus: true,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 15),
                        decoration: _inputDecoration('Reward name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: _inputDecoration('Description (optional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15),
                  decoration: _inputDecoration('Coin cost'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final t = titleCtrl.text.trim();
                      if (t.isEmpty) return;
                      final cost = int.tryParse(costCtrl.text) ?? 50;
                      ref.read(rewardsProvider.notifier).addReward(
                            title: t,
                            description: descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            cost: cost,
                            emoji: emoji,
                          );
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sakura,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Add Reward  ✦',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textMuted, fontSize: 15),
        filled: true,
        fillColor: AppColors.bgDeep,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.sakura, width: 1.5),
        ),
      );
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.onRedeem,
  });

  final Reward reward;
  final bool canAfford;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRedeem,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canAfford
                ? AppColors.coinGold.withOpacity(0.5)
                : AppColors.surfaceBorder,
            width: canAfford ? 1.5 : 1,
          ),
          boxShadow: canAfford
              ? [
                  BoxShadow(
                    color: AppColors.coinGold.withOpacity(0.15),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.emoji,
                  style: TextStyle(
                      fontSize: 36,
                      color: canAfford ? null : Colors.white38)),
              const Spacer(),
              Text(
                reward.title,
                style: TextStyle(
                  color: canAfford
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (reward.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  reward.description!,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.coinGold.withOpacity(0.18)
                      : AppColors.surfaceBorder.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 13,
                        color: canAfford
                            ? AppColors.coinGold
                            : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.cost}',
                      style: TextStyle(
                        color: canAfford
                            ? AppColors.coinGold
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
