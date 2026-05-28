import 'package:flutter/material.dart';

import '../../models/game_monster_definition.dart';
import '../../services/game_content_service.dart';
import '../../services/monster_spawn_service.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class MonsterEditorTab extends StatefulWidget {
  const MonsterEditorTab({super.key});

  @override
  State<MonsterEditorTab> createState() => _MonsterEditorTabState();
}

class _MonsterEditorTabState extends State<MonsterEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _hpCtrl = TextEditingController(text: '50');
  final _goldCtrl = TextEditingController(text: '30');
  final _xpCtrl = TextEditingController(text: '15');
  final _assetCtrl = TextEditingController(
    text: 'assets/images/monsters/slime.png',
  );
  final _levelCtrl = TextEditingController(text: '1');

  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _hpCtrl.dispose();
    _goldCtrl.dispose();
    _xpCtrl.dispose();
    _assetCtrl.dispose();
    _levelCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _hpCtrl.text = '50';
    _goldCtrl.text = '30';
    _xpCtrl.text = '15';
    _levelCtrl.text = '1';
    _assetCtrl.text = 'assets/images/monsters/slime.png';
  }

  Future<void> _release() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Canavar kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final def = GameMonsterDefinition(
        id: id,
        name: name,
        hp: int.tryParse(_hpCtrl.text) ?? 50,
        rewardGold: int.tryParse(_goldCtrl.text) ?? 30,
        rewardXp: int.tryParse(_xpCtrl.text) ?? 15,
        imagePath: _assetCtrl.text.trim(),
        minLevel: int.tryParse(_levelCtrl.text) ?? 1,
      );
      await GameContentService.instance.upsertMonster(id, def);
      MonsterSpawnService.instance.invalidateCache();
      _snack('✓ Canavar dünyaya salındı: $name');
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
        title: const Text('Canavarı sil'),
        content: Text('"$id" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await GameContentService.instance.deleteMonster(id);
    MonsterSpawnService.instance.invalidateCache();
    _snack('Silindi.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _load(GameMonsterDefinition m) {
    _idCtrl.text = m.id;
    _nameCtrl.text = m.name;
    _hpCtrl.text = '${m.hp}';
    _goldCtrl.text = '${m.rewardGold}';
    _xpCtrl.text = '${m.rewardXp}';
    _assetCtrl.text = m.imagePath;
    _levelCtrl.text = '${m.minLevel}';
    _snack('Düzenleniyor: ${m.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Canavar Editörü',
      subtitle: 'Sabah alarmı canavarlarını kod yazmadan yönetin.',
      form: AdminFormCard(
        title: 'Yeni canavar',
        primaryLabel: 'CANAVARI DÜNYAYA SAL',
        primaryLoading: _saving,
        onPrimary: _release,
        secondaryLabel: 'Formu temizle',
        onSecondary: _clearForm,
        children: [
          adminTextField(controller: _idCtrl, label: 'Canavar kodu', hint: 'monday_horror'),
          adminTextField(
            controller: _nameCtrl,
            label: 'Canavar adı',
            hint: 'Pazartesi Kabusu',
          ),
          adminTextField(
            controller: _hpCtrl,
            label: 'Can / HP',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _goldCtrl,
            label: 'Düşüreceği altın',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _xpCtrl,
            label: 'Düşüreceği XP',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _levelCtrl,
            label: 'Min. oyuncu seviyesi',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _assetCtrl,
            label: 'Canavar görsel yolu',
            hint: 'assets/images/monsters/...',
          ),
        ],
      ),
      listHeader: Text(
        'Aktif canavarlar',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: StreamBuilder<List<GameMonsterDefinition>>(
        stream: GameContentService.instance.watchMonsters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final monsters = snapshot.data!;
          return ListView.builder(
            shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
            physics: AdminListScrollPhysics.listPhysics(context),
            itemCount: monsters.length,
            itemBuilder: (context, index) {
              final m = monsters[index];
              return AdminEntryCard(
                title: m.name,
                subtitle:
                    'HP ${m.hp} · ${m.rewardGold}G · ${m.rewardXp} XP · Min Lv ${m.minLevel}\n${m.imagePath}',
                leading: const CircleAvatar(child: Text('👾')),
                onEdit: () => _load(m),
                onDelete: () => _delete(m.id),
              );
            },
          );
        },
      ),
    );
  }
}
