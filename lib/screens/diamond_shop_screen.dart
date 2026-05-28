import 'dart:async';

import 'package:flutter/material.dart';

import '../models/premium_package.dart';
import '../services/game_content_service.dart';
import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/pixel_asset_image.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

/// Premium elmas mağazası — IAP simülasyonu.
class DiamondShopScreen extends StatefulWidget {
  const DiamondShopScreen({super.key});

  @override
  State<DiamondShopScreen> createState() => _DiamondShopScreenState();
}

class _DiamondShopScreenState extends State<DiamondShopScreen> {
  int _diamonds = 0;
  bool _loading = true;
  String? _purchasingId;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDiamonds());
  }

  Future<void> _loadDiamonds() async {
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() {
      _diamonds = player.diamonds;
      _loading = false;
    });
  }

  Future<void> _purchase(PremiumPackage package) async {
    if (_purchasingId != null) return;
    setState(() => _purchasingId = package.id);

    final added = await PlayerService.instance.simulatePremiumPurchase(
      package.diamondAmount,
    );

    if (!mounted) return;
    setState(() => _purchasingId = null);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuestTheme.surface,
        title: Text(
          'SATIN ALMA BAŞARILI',
          style: pixelTextStyle(fontSize: 14, color: const Color(0xFF4FB2FF)),
        ),
        content: Text(
          '${package.name} satın alındı!\n+$added 💎 hesabına eklendi.\n\n(Gerçek IAP entegrasyonu yakında)',
          style: pixelTextStyle(fontSize: 11),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HARİKA'),
          ),
        ],
      ),
    );

    await _loadDiamonds();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4FB2FF)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ELMAS MAĞAZASI')),
      backgroundColor: QuestTheme.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060610), Color(0xFF0A1528)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _DiamondHeader(diamonds: _diamonds),
              ),
              Expanded(
                child: StreamBuilder<List<PremiumPackage>>(
                  stream: GameContentService.instance.watchPremiumPackages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Paketler yüklenemedi.\n${snapshot.error}',
                          style: pixelTextStyle(
                            fontSize: 12,
                            color: QuestTheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4FB2FF),
                        ),
                      );
                    }
                    final packages = snapshot.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: packages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final pkg = packages[index];
                        final busy = _purchasingId == pkg.id;
                        return _PackageCard(
                          package: pkg,
                          busy: busy,
                          onPurchase: () => _purchase(pkg),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiamondHeader extends StatelessWidget {
  const _DiamondHeader({required this.diamonds});

  final int diamonds;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💎', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELMAS',
                style: pixelTextStyle(
                  fontSize: 11,
                  color: QuestTheme.onSurfaceMuted,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '$diamonds',
                style: pixelTextStyle(
                  fontSize: 24,
                  color: const Color(0xFF4FB2FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.busy,
    required this.onPurchase,
  });

  final PremiumPackage package;
  final bool busy;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    return RetroWindow(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PixelAssetImage(
            imagePath: package.iconPath,
            width: 56,
            height: 56,
            placeholderSeed: package.id,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(package.name, style: pixelTextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '💎 ${package.diamondAmount} elmas',
                  style: pixelTextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4FB2FF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  package.formattedPrice,
                  style: pixelTextStyle(
                    fontSize: 11,
                    color: QuestTheme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: RetroArcadeButton(
              label: busy ? '...' : 'SATIN AL',
              height: 40,
              fontSize: 11,
              backgroundColor: const Color(0xFF1A3D6B),
              foregroundColor: const Color(0xFF4FB2FF),
              onPressed: busy ? () {} : onPurchase,
            ),
          ),
        ],
      ),
    );
  }
}
