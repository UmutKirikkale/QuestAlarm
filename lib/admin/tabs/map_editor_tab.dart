import 'package:flutter/material.dart';

import '../../models/game_map_definition.dart';
import '../../models/shop_currency.dart';
import '../../services/admin_image_upload_service.dart';
import '../../services/game_content_service.dart';
import '../../widgets/pixel_asset_image.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class MapEditorTab extends StatefulWidget {
  const MapEditorTab({super.key});

  @override
  State<MapEditorTab> createState() => _MapEditorTabState();
}

class _MapEditorTabState extends State<MapEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _levelCtrl = TextEditingController(text: '1');
  final _monsterCtrl = TextEditingController(text: '3');
  final _priceCtrl = TextEditingController(text: '0');
  final _bgCtrl = TextEditingController(
    text: 'assets/images/maps/bedroom.png',
  );

  ShopCurrency _shopCurrency = ShopCurrency.gold;
  bool _isProOnly = false;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _levelCtrl.dispose();
    _monsterCtrl.dispose();
    _priceCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _levelCtrl.text = '1';
    _monsterCtrl.text = '3';
    _priceCtrl.text = '0';
    _bgCtrl.text = 'assets/images/maps/bedroom.png';
    setState(() {
      _shopCurrency = ShopCurrency.gold;
      _isProOnly = false;
    });
  }

  Future<void> _addMap() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Harita kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final def = GameMapDefinition(
        id: id,
        name: name,
        requiredLevel: int.tryParse(_levelCtrl.text) ?? 1,
        monsterCount: int.tryParse(_monsterCtrl.text) ?? 3,
        backgroundImagePath: _bgCtrl.text.trim().isEmpty
            ? 'assets/images/maps/$id.png'
            : _bgCtrl.text.trim(),
        unlockPrice: int.tryParse(_priceCtrl.text) ?? 0,
        shopCurrency: _shopCurrency,
        isProOnly: _isProOnly,
      );
      await GameContentService.instance.upsertMap(id, def);
      _snack('✓ Harita eklendi: $name');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    if (id.isEmpty) {
      _snack('Önce harita kodunu girin, sonra görsel yükleyin.');
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final url = await AdminImageUploadService.instance.pickAndUploadImage(
        folder: 'maps',
        entityId: id,
      );
      if (url != null) {
        _bgCtrl.text = url;
        setState(() {});
        _snack('Harita görseli yüklendi.');
      }
    } catch (e) {
      _snack('Görsel yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteMap(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Haritayı sil'),
        content: Text('"$id" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await GameContentService.instance.deleteMap(id);
    _snack('Silindi.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loadMap(GameMapDefinition m) {
    _idCtrl.text = m.id;
    _nameCtrl.text = m.name;
    _levelCtrl.text = '${m.requiredLevel}';
    _monsterCtrl.text = '${m.monsterCount}';
    _bgCtrl.text = m.backgroundImagePath;
    _priceCtrl.text = '${m.unlockPrice}';
    setState(() {
      _shopCurrency = m.shopCurrency;
      _isProOnly = m.isProOnly;
    });
    _snack('Düzenleniyor: ${m.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Harita & Zindan',
      subtitle: 'Sabah alarmı sonrası oynanacak zindanları tanımlayın.',
      form: AdminFormCard(
        title: 'Yeni zindan',
        primaryLabel: 'Haritayı kaydet',
        primaryLoading: _saving,
        onPrimary: _addMap,
        secondaryLabel: 'Formu temizle',
        onSecondary: _clearForm,
        children: [
          adminTextField(controller: _idCtrl, label: 'Harita kodu', hint: 'lava_cave'),
          adminTextField(controller: _nameCtrl, label: 'Harita adı', hint: 'Lav Mağarası'),
          adminTextField(
            controller: _levelCtrl,
            label: 'Gerekli seviye',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _monsterCtrl,
            label: 'Toplam canavar',
            keyboardType: TextInputType.number,
          ),
          adminShopCurrencyPicker(
            value: _shopCurrency,
            label: 'Açılış ücreti para birimi',
            onChanged: (c) => setState(() => _shopCurrency = c),
          ),
          adminTextField(
            controller: _priceCtrl,
            label: 'Açılış ücreti (0 = ücretsiz)',
            hint: 'Elmaslı harita için örn: 100',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _bgCtrl,
            label: 'Arka plan görseli',
            hint: 'assets/... veya https://...',
          ),
          SwitchListTile(
            title: const Text('Sadece PRO Üyeler Girebilsin'),
            subtitle: const Text('isProOnly → Firestore'),
            value: _isProOnly,
            onChanged: (v) => setState(() => _isProOnly = v),
          ),
          AdminSecondaryButton(
            label: _uploadingImage ? 'Yükleniyor...' : 'Bilgisayardan görsel seç',
            icon: Icons.upload_file_outlined,
            onPressed: _uploadingImage ? null : _uploadImage,
          ),
          const SizedBox(height: 12),
          if (_bgCtrl.text.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  PixelAssetImage(
                    imagePath: _bgCtrl.text.trim(),
                    width: 72,
                    height: 52,
                    fit: BoxFit.cover,
                    placeholderSeed: _idCtrl.text.trim(),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Önizleme',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      listHeader: Text(
        'Aktif haritalar',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: StreamBuilder<List<GameMapDefinition>>(
        stream: GameContentService.instance.watchMaps(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final maps = snapshot.data!;
          if (maps.isEmpty) {
            return const Center(child: Text('Henüz harita yok.'));
          }
          return ListView.builder(
            shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
            physics: AdminListScrollPhysics.listPhysics(context),
            itemCount: maps.length,
            itemBuilder: (context, index) {
              final m = maps[index];
              return AdminEntryCard(
                title: m.name,
                subtitle:
                    'Min Lv ${m.requiredLevel} · ${m.monsterCount} canavar · '
                    '${m.requiresPurchase ? m.shopCurrency.formatPrice(m.unlockPrice) : "Ücretsiz"}\n'
                    '${m.backgroundImagePath}',
                leading: const CircleAvatar(child: Text('🗺')),
                onEdit: () => _loadMap(m),
                onDelete: () => _deleteMap(m.id),
              );
            },
          );
        },
      ),
    );
  }
}
