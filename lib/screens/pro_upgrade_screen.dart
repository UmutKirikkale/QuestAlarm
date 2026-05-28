import 'dart:async';

import 'package:flutter/material.dart';

import '../services/player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';
import '../widgets/retro_arcade_button.dart';
import '../widgets/retro_window.dart';

/// Pro üyelik — IAP simülasyonu.
class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  bool _loading = true;
  bool _isPro = false;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final player = await PlayerService.instance.loadPlayer();
    if (!mounted) return;
    setState(() {
      _isPro = player.isPro;
      _loading = false;
    });
  }

  Future<void> _purchasePro() async {
    if (_purchasing || _isPro) return;
    setState(() => _purchasing = true);

    final ok = await PlayerService.instance.activateProMembership();

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Satın alma tamamlanamadı.'),
          backgroundColor: QuestTheme.error,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: QuestTheme.surface,
        title: Text(
          'PRO ÜYELİK AKTİF!',
          style: pixelTextStyle(fontSize: 14, color: const Color(0xFFFFD54F)),
        ),
        content: Text(
          'Artık reklamsızsın ve Pro bonuslarından yararlanıyorsun.\n\n'
          '(Gerçek IAP entegrasyonu yakında)',
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

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: QuestTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: QuestTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: QuestTheme.background,
      appBar: AppBar(title: const Text('PRO ÜYELİK')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RetroWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _isPro ? '👑 PRO ÜYESİN' : 'PRO SÜRÜME GEÇ',
                      style: pixelTextStyle(
                        fontSize: 16,
                        color: const Color(0xFFFFD54F),
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPro
                          ? 'Tüm Pro ayrıcalıkları aktif.'
                          : 'Reklamsız oyna, bonus XP/altın kazan, '
                              'tüm etkinliklere katıl ve Pro zindanlarını aç.',
                      style: pixelTextStyle(
                        fontSize: 11,
                        color: QuestTheme.onSurfaceMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    _benefitRow('Reklamsız deneyim'),
                    _benefitRow('Bonus XP ve altın çarpanları'),
                    _benefitRow('Ucuz ekipman tamiri'),
                    _benefitRow('Sınırsız etkinlik katılımı'),
                    _benefitRow('Pro özel zindanlar'),
                  ],
                ),
              ),
              const Spacer(),
              if (_isPro)
                Text(
                  'Teşekkürler, kahraman!',
                  textAlign: TextAlign.center,
                  style: pixelTextStyle(fontSize: 12, color: QuestTheme.primary),
                )
              else
                RetroArcadeButton(
                  label: _purchasing ? 'İŞLENİYOR...' : 'PRO SÜRÜME GEÇ',
                  icon: '👑',
                  backgroundColor: const Color(0xFF4A3800),
                  foregroundColor: const Color(0xFFFFD54F),
                  onPressed: _purchasing ? () {} : _purchasePro,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('✦', style: pixelTextStyle(fontSize: 10, color: QuestTheme.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: pixelTextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
