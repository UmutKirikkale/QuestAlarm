import 'package:flutter/material.dart';

import '../../models/global_settings.dart';
import '../../services/global_settings_service.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_form_card.dart';

class GlobalSettingsTab extends StatefulWidget {
  const GlobalSettingsTab({super.key});

  @override
  State<GlobalSettingsTab> createState() => _GlobalSettingsTabState();
}

class _GlobalSettingsTabState extends State<GlobalSettingsTab> {
  final _questCtrl = TextEditingController();
  final _levelXpExpCtrl = TextEditingController(
    text: '${GlobalSettings.defaultLevelXpExponent}',
  );
  final _streakBonusCtrl = TextEditingController(
    text: '${GlobalSettings.defaultStreakBonusPerDay}',
  );
  final _maxStreakCtrl = TextEditingController(
    text: '${GlobalSettings.defaultMaxStreakMultiplier}',
  );
  final _repairCostCtrl = TextEditingController(
    text: '${GlobalSettings.defaultRepairCostPerDurability}',
  );
  final _proXpCtrl = TextEditingController(
    text: '${GlobalSettings.defaultProXpMultiplier}',
  );
  final _proGoldCtrl = TextEditingController(
    text: '${GlobalSettings.defaultProGoldMultiplier}',
  );
  final _proRepairCtrl = TextEditingController(
    text: '${GlobalSettings.defaultProRepairCost}',
  );

  bool _maintenance = false;
  bool _loaded = false;
  bool _savingQuest = false;
  bool _savingEconomy = false;

  static const _neon = Color(0xFF00E5A0);

  @override
  void dispose() {
    _questCtrl.dispose();
    _levelXpExpCtrl.dispose();
    _streakBonusCtrl.dispose();
    _maxStreakCtrl.dispose();
    _repairCostCtrl.dispose();
    _proXpCtrl.dispose();
    _proGoldCtrl.dispose();
    _proRepairCtrl.dispose();
    super.dispose();
  }

  void _applySettings(GlobalSettings s) {
    _maintenance = s.maintenanceMode;
    _questCtrl.text = s.dailyQuestText;
    _levelXpExpCtrl.text = _formatNum(s.levelXpExponent);
    _streakBonusCtrl.text = _formatNum(s.streakBonusPerDay);
    _maxStreakCtrl.text = _formatNum(s.maxStreakMultiplier);
    _repairCostCtrl.text = _formatNum(s.repairCostPerDurability);
    _proXpCtrl.text = _formatNum(s.proXpMultiplier);
    _proGoldCtrl.text = _formatNum(s.proGoldMultiplier);
    _proRepairCtrl.text = _formatNum(s.proRepairCost);
  }

  String _formatNum(double v) {
    if (v == v.roundToDouble()) return '${v.toInt()}';
    return v.toString();
  }

  double? _parseDouble(String text, String fieldLabel) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    if (v == null) {
      _snack('$fieldLabel geçerli bir sayı olmalı.');
      return null;
    }
    return v;
  }

  Future<void> _saveQuest() async {
    setState(() => _savingQuest = true);
    try {
      await GlobalSettingsService.instance
          .setDailyQuestText(_questCtrl.text.trim());
      _snack('Günün görevi kaydedildi.');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _savingQuest = false);
    }
  }

  Future<void> _saveEconomy() async {
    final levelXp = _parseDouble(_levelXpExpCtrl.text, 'Seviye XP üssü');
    if (levelXp == null) return;
    final streakBonus = _parseDouble(_streakBonusCtrl.text, 'Seri bonusu');
    if (streakBonus == null) return;
    final maxStreak = _parseDouble(_maxStreakCtrl.text, 'Maks. seri çarpanı');
    if (maxStreak == null) return;
    final repairCost =
        _parseDouble(_repairCostCtrl.text, 'Tamir maliyeti');
    if (repairCost == null) return;
    final proXp = _parseDouble(_proXpCtrl.text, 'Pro XP çarpanı');
    if (proXp == null) return;
    final proGold = _parseDouble(_proGoldCtrl.text, 'Pro altın çarpanı');
    if (proGold == null) return;
    final proRepair = _parseDouble(_proRepairCtrl.text, 'Pro tamir maliyeti');
    if (proRepair == null) return;

    if (levelXp <= 0 || maxStreak < 1 || proXp <= 0 || proGold <= 0) {
      _snack('XP üssü > 0, maks. çarpan ≥ 1 ve Pro çarpanları > 0 olmalı.');
      return;
    }

    setState(() => _savingEconomy = true);
    try {
      await GlobalSettingsService.instance.saveEconomySettings(
        levelXpExponent: levelXp,
        streakBonusPerDay: streakBonus,
        maxStreakMultiplier: maxStreak,
        repairCostPerDurability: repairCost,
        proXpMultiplier: proXp,
        proGoldMultiplier: proGold,
        proRepairCost: proRepair,
      );
      _snack('Ekonomi ayarları kaydedildi — mobilde anında geçerli.');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _savingEconomy = false);
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    setState(() => _maintenance = value);
    try {
      await GlobalSettingsService.instance.setMaintenanceMode(value);
      _snack(value ? 'Bakım modu AÇIK' : 'Bakım modu KAPALI');
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GlobalSettings>(
      stream: GlobalSettingsService.instance.watchSettings(),
      builder: (context, snapshot) {
        if (snapshot.hasData && !_loaded) {
          _applySettings(snapshot.data!);
          _loaded = true;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Küresel Etkinlikler & Bakım',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: _neon,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tek doküman: global_settings/app — tüm oyunculara anında yansır.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Card(
                  color: const Color(0xFF121820),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _maintenance
                          ? Colors.orangeAccent
                          : _neon.withValues(alpha: 0.3),
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Bakım Modu (Maintenance)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Açıkken mobil uygulama kilit ekranı gösterir.',
                    ),
                    value: _maintenance,
                    activeThumbColor: _neon,
                    onChanged: _toggleMaintenance,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  color: const Color(0xFF121820),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Günün Görevi (Daily Quest)',
                          style: TextStyle(
                            color: _neon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _questCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Ana ekranda kayan yazı',
                            hintText:
                                'Bugün büyücüler 2 kat fazla XP kazanacak!',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminPrimaryButton(
                          label: 'Görev metnini kaydet',
                          loading: _savingQuest,
                          onPressed: _saveQuest,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AdminFormCard(
                  title: 'Oyun Ekonomisi ve Denge Ayarları',
                  primaryLabel: 'Ekonomi ayarlarını kaydet',
                  primaryLoading: _savingEconomy,
                  onPrimary: _saveEconomy,
                  children: [
                    adminTextField(
                      controller: _levelXpExpCtrl,
                      label: 'Seviye XP Çarpanı Üssü',
                      hint: 'Varsayılan: ${GlobalSettings.defaultLevelXpExponent}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    adminTextField(
                      controller: _streakBonusCtrl,
                      label: 'Streak (Seri) Başına Bonus Çarpanı',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultStreakBonusPerDay} (%10/gün)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    adminTextField(
                      controller: _maxStreakCtrl,
                      label: 'Maksimum Streak Çarpan Sınırı',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultMaxStreakMultiplier}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    adminTextField(
                      controller: _repairCostCtrl,
                      label: 'Dayanıklılık Başına Tamir Maliyeti',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultRepairCostPerDurability} altın / puan',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    Text(
                      'Örnek: 7 günlük seri → çarpan ≈ '
                      '${(1 + 7 * GlobalSettings.defaultStreakBonusPerDay).clamp(1.0, GlobalSettings.defaultMaxStreakMultiplier).toStringAsFixed(2)}×',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 28),
                    Text(
                      'PRO KULLANICI DENGELERİ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFFFD54F),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    adminTextField(
                      controller: _proXpCtrl,
                      label: 'Pro XP Çarpanı (proXpMultiplier)',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultProXpMultiplier}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    adminTextField(
                      controller: _proGoldCtrl,
                      label: 'Pro Altın Çarpanı (proGoldMultiplier)',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultProGoldMultiplier}',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    adminTextField(
                      controller: _proRepairCtrl,
                      label: 'Pro Tamir Maliyeti (proRepairCost)',
                      hint:
                          'Varsayılan: ${GlobalSettings.defaultProRepairCost} altın / puan',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
