import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class CoinBadge extends ConsumerStatefulWidget {
  const CoinBadge({super.key});

  @override
  ConsumerState<CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends ConsumerState<CoinBadge> {
  int _prevBalance = 0;
  bool _bump = false;

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final balance = wallet.balance;

    if (balance != _prevBalance) {
      _prevBalance = balance;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _bump = true);
        Future.delayed(600.ms, () {
          if (mounted) setState(() => _bump = false);
        });
      });
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.coinGlow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.coinGold.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✦', style: TextStyle(color: Colors.white, fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '$balance',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );

    if (_bump) {
      badge = badge
          .animate()
          .scale(
            duration: 200.ms,
            begin: const Offset(1, 1),
            end: const Offset(1.2, 1.2),
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            duration: 200.ms,
            begin: const Offset(1.2, 1.2),
            end: const Offset(1, 1),
          );
    }

    return badge;
  }
}
