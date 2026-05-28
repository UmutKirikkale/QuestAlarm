import 'package:flutter/material.dart';

import '../../models/game_event_definition.dart';
import '../../services/game_content_service.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class EventEditorTab extends StatefulWidget {
  const EventEditorTab({super.key});

  @override
  State<EventEditorTab> createState() => _EventEditorTabState();
}

class _EventEditorTabState extends State<EventEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController(text: '3');
  final _rewardCtrl = TextEditingController(text: '100');

  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _descCtrl.clear();
    _targetCtrl.text = '3';
    _rewardCtrl.text = '100';
    setState(() => _isActive = true);
  }

  Future<void> _publish() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Etkinlik kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final event = GameEventDefinition(
        id: id,
        name: name,
        description: _descCtrl.text.trim(),
        targetCount: int.tryParse(_targetCtrl.text) ?? 1,
        rewardGold: int.tryParse(_rewardCtrl.text) ?? 0,
        isActive: _isActive,
      );
      await GameContentService.instance.upsertEvent(id, event);
      _snack('✓ Etkinlik yayınlandı: $name');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Etkinliği sil'),
        content: Text('"$id" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await GameContentService.instance.deleteEvent(id);
    _snack('Silindi.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _load(GameEventDefinition e) {
    _idCtrl.text = e.id;
    _nameCtrl.text = e.name;
    _descCtrl.text = e.description;
    _targetCtrl.text = '${e.targetCount}';
    _rewardCtrl.text = '${e.rewardGold}';
    setState(() => _isActive = e.isActive);
    _snack('Düzenleniyor: ${e.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Etkinlik Yöneticisi',
      subtitle: 'Canlı etkinlikleri yayınlayın. Oyuncular sabah zaferlerinde ilerleme kazanır.',
      form: AdminFormCard(
        title: 'Yeni etkinlik',
        primaryLabel: 'ETKİNLİĞİ YAYINLA',
        primaryLoading: _saving,
        onPrimary: _publish,
        secondaryLabel: 'Formu temizle',
        onSecondary: _clearForm,
        children: [
          adminTextField(controller: _idCtrl, label: 'Etkinlik kodu', hint: 'early_bird'),
          adminTextField(
            controller: _nameCtrl,
            label: 'Etkinlik adı',
            hint: 'Erken Kuş Maratonu',
          ),
          adminTextField(
            controller: _descCtrl,
            label: 'Etkinlik açıklaması',
            hint: '3 gün üst üste alarmı 5 saniyede kapat',
            maxLines: 3,
          ),
          adminTextField(
            controller: _targetCtrl,
            label: 'Hedef sayaç',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _rewardCtrl,
            label: 'Ödül altın miktarı',
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            title: const Text('Yayında (aktif)'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
      listHeader: Text(
        'Yayındaki etkinlikler',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: StreamBuilder<List<GameEventDefinition>>(
        stream: GameContentService.instance.watchAllEventsAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text('Henüz etkinlik yok.'));
          }
          return ListView.builder(
            shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
            physics: AdminListScrollPhysics.listPhysics(context),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final e = events[index];
              return AdminEntryCard(
                title: e.name,
                subtitle:
                    'Hedef: ${e.targetCount} · Ödül: ${e.rewardGold} altın\n'
                    '${e.description}\n'
                    'Durum: ${e.isActive ? "Aktif" : "Kapalı"}',
                leading: CircleAvatar(
                  child: Text(e.isActive ? '🎯' : '⏸'),
                ),
                onEdit: () => _load(e),
                onDelete: () => _delete(e.id),
              );
            },
          );
        },
      ),
    );
  }
}
