import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/moderated_user.dart';
import '../../services/player_moderation_service.dart';
import '../widgets/admin_buttons.dart';

/// God Mode — oyuncu moderasyonu ve manuel enjeksiyon.
class GodModeTab extends StatefulWidget {
  const GodModeTab({super.key});

  @override
  State<GodModeTab> createState() => _GodModeTabState();
}

class _GodModeTabState extends State<GodModeTab> {
  final _uidCtrl = TextEditingController();
  ModeratedUser? _selected;
  bool _busy = false;
  bool _filterProOnly = false;

  static const _neon = Color(0xFF00E5A0);

  @override
  void dispose() {
    _uidCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(String action, Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
      _snack('✓ $action tamamlandı');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _targetUid {
    final manual = _uidCtrl.text.trim();
    if (manual.isNotEmpty) return manual;
    return _selected?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GOD MODE — Oyuncu Yönetimi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _neon,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Canlı oyuncu listesi ve müşteri desteği enjeksiyonları.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              Switch(
                value: _filterProOnly,
                activeColor: const Color(0xFFFFD54F),
                onChanged: (v) => setState(() => _filterProOnly = v),
              ),
              const SizedBox(width: 8),
              const Text('Pro Kullanıcıları Filtrele'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: wide ? _buildWide() : _buildNarrow(),
          ),
        ],
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildUserTable()),
        const SizedBox(width: 16),
        SizedBox(width: 320, child: _buildInjectionPanel()),
      ],
    );
  }

  Widget _buildNarrow() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInjectionPanel(),
          const SizedBox(height: 16),
          SizedBox(height: 420, child: _buildUserTable()),
        ],
      ),
    );
  }

  Widget _buildInjectionPanel() {
    return Card(
      color: const Color(0xFF0D1218),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _neon.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Müşteri Desteği / Manuel Enjeksiyon',
              style: TextStyle(
                color: _neon,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uidCtrl,
              decoration: InputDecoration(
                labelText: 'Oyuncu UID',
                hintText: _selected?.uid ?? 'Tablodan seç veya yapıştır',
                suffixIcon: _selected != null
                    ? IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _selected!.uid),
                          );
                          _snack('UID kopyalandı');
                        },
                      )
                    : null,
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 8),
              Text(
                'Seçili: Lv ${_selected!.player.level} · '
                '${_selected!.player.gold}G · '
                '💎${_selected!.player.diamonds}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            AdminPrimaryButton(
              label: '+500 Altın',
              icon: Icons.monetization_on_outlined,
              loading: _busy,
              onPressed: _targetUid.isEmpty
                  ? null
                  : () => _run('Altın', () => PlayerModerationService.instance
                      .grantGold(_targetUid, 500)),
            ),
            const SizedBox(height: 8),
            AdminPrimaryButton(
              label: '+50 Elmas',
              icon: Icons.diamond_outlined,
              loading: _busy,
              onPressed: _targetUid.isEmpty
                  ? null
                  : () => _run('Elmas', () => PlayerModerationService.instance
                      .grantDiamonds(_targetUid, 50)),
            ),
            const SizedBox(height: 8),
            AdminSecondaryButton(
              label: 'Epik Eşya Gönder',
              icon: Icons.sports_martial_arts_outlined,
              onPressed: _targetUid.isEmpty
                  ? null
                  : () => _run('Eşya', () => PlayerModerationService.instance
                      .grantEpicItem(_targetUid)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<List<ModeratedUser>>(
        stream: PlayerModerationService.instance.watchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var users = snapshot.data!;
          if (_filterProOnly) {
            users = users.where((u) => u.player.isPro).toList();
          }
          if (users.isEmpty) {
            return Center(
              child: Text(
                _filterProOnly
                    ? 'Pro oyuncu bulunamadı.'
                    : 'Henüz kayıtlı oyuncu yok.',
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  _neon.withValues(alpha: 0.12),
                ),
                columns: const [
                  DataColumn(label: Text('UID')),
                  DataColumn(label: Text('Üyelik')),
                  DataColumn(label: Text('Lv')),
                  DataColumn(label: Text('Altın')),
                  DataColumn(label: Text('Elmas')),
                  DataColumn(label: Text('Seri')),
                  DataColumn(label: Text('Durum')),
                  DataColumn(label: Text('İşlem')),
                ],
                rows: users.map((u) {
                  final selected = _selected?.uid == u.uid;
                  final isPro = u.player.isPro;
                  return DataRow(
                    selected: selected,
                    color: WidgetStateProperty.resolveWith((states) {
                      if (isPro) {
                        return const Color(0xFF3D3208).withValues(alpha: 0.85);
                      }
                      return null;
                    }),
                    onSelectChanged: (_) {
                      setState(() {
                        _selected = u;
                        _uidCtrl.text = u.uid;
                      });
                    },
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            u.uid.length > 12
                                ? '${u.uid.substring(0, 12)}…'
                                : u.uid,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          isPro ? '👑 PRO' : '—',
                          style: TextStyle(
                            color: isPro
                                ? const Color(0xFFFFD54F)
                                : Colors.white54,
                            fontWeight:
                                isPro ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      DataCell(Text('${u.player.level}')),
                      DataCell(Text('${u.player.gold}')),
                      DataCell(Text('${u.player.diamonds}')),
                      DataCell(Text('${u.player.streak}')),
                      DataCell(
                        Text(
                          u.isBanned ? 'BAN' : 'Aktif',
                          style: TextStyle(
                            color: u.isBanned ? Colors.redAccent : _neon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdminCompactButton(
                              label: 'Sıfırla',
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        'Sıfırlama',
                                        () => PlayerModerationService.instance
                                            .resetAccountProgress(u.uid),
                                      ),
                            ),
                            const SizedBox(width: 6),
                            AdminCompactButton(
                              label: u.isBanned ? 'Ban Kaldır' : 'Banla',
                              destructive: !u.isBanned,
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        'Ban',
                                        () => PlayerModerationService.instance
                                            .setBanned(u.uid, !u.isBanned),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
