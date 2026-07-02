import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/reward.dart';
import '../providers/rewards_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

/// Shop screen — same OneUI split layout as the Tasks screen.
/// Viewing area: hero gradient with wallet balance. Interaction area: reward grid.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(rewardsProvider);
    final wallet = ref.watch(walletProvider);
    final settings = ref.watch(settingsProvider);
    final palette =
        GlassPalette(isDark: settings.isDarkMode, accent: settings.accentColor);

    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.36).clamp(240.0, 360.0);

    return Container(
      color: palette.bg,
      child: CustomScrollView(
        physics:
            const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Viewing area: hero ─────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: false,
            delegate: _ShopHeroDelegate(
              maxHeight: heroHeight,
              wallet: wallet,
              palette: palette,
              accent: settings.accentColor,
              headerStyle: settings.headerStyle,
            ),
          ),

          // ── Section header ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rewards',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                      Text(
                        'Spend your hard-earned coins',
                        style: TextStyle(
                            fontSize: 13, color: palette.textMuted),
                      ),
                    ],
                  ),
                  _AddButton(palette: palette, onTap: () => _showAddReward(context, ref, palette)),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Reward grid ────────────────────────────────────────────────────
          if (rewards.isEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: screenHeight * 0.4,
                child: _EmptyShop(palette: palette),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _RewardCard(
                    reward: rewards[i],
                    canAfford: wallet.balance >= rewards[i].cost,
                    palette: palette,
                    accent: settings.accentColor,
                    onRedeem: () => _redeem(context, ref, rewards[i], palette),
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
      BuildContext context, WidgetRef ref, Reward reward, GlassPalette palette) async {
    final wallet = ref.read(walletProvider);
    if (wallet.balance < reward.cost) {
      _snack(context, palette,
          'Need ${reward.cost - wallet.balance} more coins  (；一_一)');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(reward: reward, palette: palette),
    );
    if (confirmed == true) {
      final success =
          await ref.read(rewardsProvider.notifier).redeem(reward);
      if (context.mounted) {
        _snack(context, palette,
            success ? 'Enjoy! ${reward.emoji}  ✦' : 'Not enough coins  (；一_一)');
      }
    }
  }

  void _snack(BuildContext context, GlassPalette palette, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: palette.textPrimary)),
      backgroundColor: palette.surface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _showAddReward(BuildContext context, WidgetRef ref, GlassPalette palette) {
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
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: palette.border)),
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
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Custom Reward',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final emojis = [
                          '🎁', '🍡', '📱', '🎮', '😴', '🍕', '🎵',
                          '🎬', '🛁', '☕', '🍫', '🎯', '🧸', '🌸',
                        ];
                        final picked = await showDialog<String>(
                          context: ctx,
                          builder: (_) => SimpleDialog(
                            backgroundColor: palette.surface,
                            children: [
                              Wrap(
                                children: emojis
                                    .map((e) => InkWell(
                                          onTap: () => Navigator.pop(ctx, e),
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
                          color: palette.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border),
                        ),
                        child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 26))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: titleCtrl,
                        autofocus: true,
                        style: TextStyle(
                            color: palette.textPrimary, fontSize: 15),
                        decoration: _inputDec('Reward name', palette),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  style:
                      TextStyle(color: palette.textPrimary, fontSize: 15),
                  decoration: _inputDec('Description (optional)', palette),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  style:
                      TextStyle(color: palette.textPrimary, fontSize: 15),
                  decoration: _inputDec('Coin cost', palette),
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
                      backgroundColor: palette.accent,
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

  InputDecoration _inputDec(String hint, GlassPalette palette) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: palette.textMuted, fontSize: 15),
        filled: true,
        fillColor: palette.bgSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      );
}

// ─── Hero delegate ────────────────────────────────────────────────────────────

class _ShopHeroDelegate extends SliverPersistentHeaderDelegate {
  const _ShopHeroDelegate({
    required this.maxHeight,
    required this.wallet,
    required this.palette,
    required this.accent,
    required this.headerStyle,
  });

  final double maxHeight;
  final dynamic wallet;
  final GlassPalette palette;
  final Color accent;
  final HeaderStyle headerStyle;

  @override
  double get minExtent => 0;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress =
        maxHeight <= 0 ? 0.0 : (shrinkOffset / maxHeight).clamp(0.0, 1.0);
    final opacity = (1 - progress * 1.4).clamp(0.0, 1.0);

    return ClipRect(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, -shrinkOffset * 0.35),
          child: SizedBox(
            height: maxHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background — same gradient options as tasks
                _ShopHeroBg(style: headerStyle),
                // Scrim
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x10000000), Color(0xCC000000)],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
                // Wallet balance card
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: _WalletCard(
                      wallet: wallet, palette: palette, accent: accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ShopHeroDelegate old) =>
      old.maxHeight != maxHeight ||
      old.wallet != wallet ||
      old.accent != accent ||
      old.headerStyle != headerStyle;
}

class _ShopHeroBg extends StatelessWidget {
  const _ShopHeroBg({required this.style});
  final HeaderStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case HeaderStyle.photo:
        return Image.asset('assets/images/header_hero.webp', fit: BoxFit.cover);
      case HeaderStyle.sakuraDusk:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6FA5), Color(0xFF6A3E9C), Color(0xFF1A1025)],
            ),
          ),
        );
      case HeaderStyle.cursedViolet:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF120B1C), Color(0xFF3A2566), Color(0xFF6A1B2F)],
            ),
          ),
        );
      case HeaderStyle.mintDawn:
        return const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7DE0D3), Color(0xFF2D6E63), Color(0xFF12251F)],
            ),
          ),
        );
    }
  }
}

// ─── Wallet balance card ──────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  const _WalletCard(
      {required this.wallet, required this.palette, required this.accent});

  final dynamic wallet;
  final GlassPalette palette;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Coin icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.coinGold, AppColors.coinGoldDeep],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coinGold.withOpacity(0.5),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Center(
                child: Text('✦',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                Text(
                  '${wallet.balance} coins',
                  style: const TextStyle(
                    color: AppColors.coinGold,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatChip(
                    label: 'earned',
                    value: '${wallet.totalEarnedLifetime}'),
                const SizedBox(height: 4),
                _StatChip(
                    label: 'spent', value: '${wallet.totalSpentLifetime}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}

// ─── Add button ───────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.palette, required this.onTap});
  final GlassPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: palette.accent),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: TextStyle(
                color: palette.accent,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty shop ───────────────────────────────────────────────────────────────

class _EmptyShop extends StatelessWidget {
  const _EmptyShop({required this.palette});
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🛍️',
              style: TextStyle(
                  fontSize: 48, color: palette.accent.withOpacity(0.6)))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                duration: 1800.ms,
                begin: const Offset(0.88, 0.88),
                end: const Offset(1.12, 1.12),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 16),
          Text('No rewards yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary)),
          const SizedBox(height: 6),
          Text('Tap Add to create your first reward',
              style: TextStyle(fontSize: 13, color: palette.textMuted)),
        ],
      ),
    );
  }
}

// ─── Reward card ──────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.canAfford,
    required this.palette,
    required this.accent,
    required this.onRedeem,
  });

  final Reward reward;
  final bool canAfford;
  final GlassPalette palette;
  final Color accent;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRedeem,
      child: LiquidGlass(
        borderRadius: 20,
        borderColor: canAfford ? accent.withOpacity(0.5) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + affordability dot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reward.emoji,
                    style: TextStyle(
                        fontSize: 34,
                        color: canAfford ? null : Colors.white38),
                  ),
                  if (canAfford)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: accent.withOpacity(0.6),
                              blurRadius: 6)
                        ],
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                reward.title,
                style: TextStyle(
                  color: canAfford ? palette.textPrimary : palette.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (reward.description != null) ...[
                const SizedBox(height: 3),
                Text(
                  reward.description!,
                  style:
                      TextStyle(color: palette.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              // Coin cost pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: canAfford
                      ? AppColors.coinGold.withOpacity(0.18)
                      : palette.border.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on,
                        size: 13,
                        color: canAfford
                            ? AppColors.coinGold
                            : palette.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.cost}',
                      style: TextStyle(
                        color: canAfford
                            ? AppColors.coinGold
                            : palette.textMuted,
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

// ─── Confirm dialog ───────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.reward, required this.palette});
  final Reward reward;
  final GlassPalette palette;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Redeem ${reward.emoji} ${reward.title}?',
        style: TextStyle(color: palette.textPrimary, fontSize: 17),
      ),
      content: Text(
        'This will cost ${reward.cost} coins.',
        style: TextStyle(color: palette.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child:
              Text('Cancel', style: TextStyle(color: palette.textMuted)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coinGold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Redeem  ✦'),
        ),
      ],
    );
  }
}
