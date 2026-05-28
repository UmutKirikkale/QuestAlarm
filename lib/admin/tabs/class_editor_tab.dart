import 'package:flutter/material.dart';

import '../../models/game_class_definition.dart';
import '../../services/game_content_service.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class ClassEditorTab extends StatefulWidget {
  const ClassEditorTab({super.key});

  @override
  State<ClassEditorTab> createState() => _ClassEditorTabState();
}

class _ClassEditorTabState extends State<ClassEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _hpCtrl = TextEditingController(text: '100');
  final _energyCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();

  ClassActionType _actionType = ClassActionType.shake;
  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _hpCtrl.dispose();
    _energyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _hpCtrl.text = '100';
    _energyCtrl.text = '0';
    _descCtrl.clear();
    setState(() => _actionType = ClassActionType.shake);
  }

  Future<void> _addClass() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Sınıf kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final def = GameClassDefinition(
        id: id,
        name: name,
        startHp: int.tryParse(_hpCtrl.text) ?? 100,
        startEnergy: int.tryParse(_energyCtrl.text) ?? 0,
        description: _descCtrl.text.trim(),
        actionType: _actionType,
      );
      await GameContentService.instance.upsertClass(id, def);
      _snack('✓ Sınıf eklendi: $name');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteClass(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sınıfı sil'),
        content: Text('"$id" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await GameContentService.instance.deleteClass(id);
    _snack('Silindi.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loadClass(GameClassDefinition c) {
    _idCtrl.text = c.id;
    _nameCtrl.text = c.name;
    _hpCtrl.text = '${c.startHp}';
    _energyCtrl.text = '${c.startEnergy}';
    _descCtrl.text = c.description;
    setState(() => _actionType = c.actionType);
    _snack('Düzenleniyor: ${c.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Sınıf Editörü',
      subtitle: 'Yeni kahraman sınıfları ekleyin. Oyuncu ilk girişte bu listeyi görür.',
      form: AdminFormCard(
        title: 'Yeni sınıf',
        primaryLabel: 'Sınıfı oyuna ekle',
        primaryLoading: _saving,
        onPrimary: _addClass,
        secondaryLabel: 'Formu temizle',
        onSecondary: _clearForm,
        children: [
          adminTextField(controller: _idCtrl, label: 'Sınıf kodu', hint: 'archer'),
          adminTextField(controller: _nameCtrl, label: 'Sınıf adı', hint: 'Okçu'),
          adminTextField(
            controller: _hpCtrl,
            label: 'Başlangıç HP',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _energyCtrl,
            label: 'Başlangıç mana / enerji',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _descCtrl,
            label: 'Açıklama',
            maxLines: 3,
          ),
          adminDropdown<ClassActionType>(
            value: _actionType,
            label: 'Savaş aksiyonu',
            items: ClassActionType.values
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(GameClassDefinition.actionTypeLabel(t)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _actionType = v ?? ClassActionType.shake),
          ),
        ],
      ),
      listHeader: Text(
        'Mevcut sınıflar',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: StreamBuilder<List<GameClassDefinition>>(
        stream: GameContentService.instance.watchClasses(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final classes = snapshot.data!;
          if (classes.isEmpty) {
            return const Center(child: Text('Henüz sınıf yok.'));
          }
          return ListView.builder(
            shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
            physics: AdminListScrollPhysics.listPhysics(context),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final c = classes[index];
              return AdminEntryCard(
                title: c.name,
                subtitle:
                    'HP ${c.startHp} · Enerji ${c.startEnergy}\n'
                    '${GameClassDefinition.actionTypeLabel(c.actionType)}',
                leading: const CircleAvatar(child: Text('⚔')),
                onEdit: () => _loadClass(c),
                onDelete: () => _deleteClass(c.id),
              );
            },
          );
        },
      ),
    );
  }
}
