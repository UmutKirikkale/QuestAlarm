import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/shop_currency.dart';
import '../../services/admin_image_upload_service.dart';
import '../../services/game_content_service.dart';
import '../../widgets/pixel_asset_image.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_firebase_status_bar.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class ItemEditorTab extends StatefulWidget {
  const ItemEditorTab({super.key});

  @override
  State<ItemEditorTab> createState() => _ItemEditorTabState();
}

class _ItemEditorTabState extends State<ItemEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '50');
  final _dmgCtrl = TextEditingController(text: '10');
  final _levelCtrl = TextEditingController(text: '1');
  final _critCtrl = TextEditingController(text: '5');
  final _assetCtrl = TextEditingController(
    text: 'assets/images/items/sword.png',
  );

  ItemType _itemType = ItemType.weapon;
  ItemRarity _rarity = ItemRarity.common;
  ShopCurrency _shopCurrency = ShopCurrency.gold;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _dmgCtrl.dispose();
    _levelCtrl.dispose();
    _critCtrl.dispose();
    _assetCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _priceCtrl.text = '50';
    _dmgCtrl.text = '10';
    _levelCtrl.text = '1';
    _critCtrl.text = '5';
    _assetCtrl.text = 'assets/images/items/sword.png';
    setState(() {
      _itemType = ItemType.weapon;
      _rarity = ItemRarity.common;
      _shopCurrency = ShopCurrency.gold;
    });
  }

  Future<void> _saveItem() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Eşya kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final item = Item(
        id: id,
        name: name,
        price: int.tryParse(_priceCtrl.text) ?? 0,
        shopCurrency: _shopCurrency,
        bonusDamage: int.tryParse(_dmgCtrl.text) ?? 0,
        requiredLevel: int.tryParse(_levelCtrl.text) ?? 1,
        rarity: _rarity,
        criticalChance: (double.tryParse(_critCtrl.text) ?? 0) / 100,
        itemType: _itemType,
        imagePath: _assetCtrl.text.trim().isEmpty
            ? Item.defaultImagePath(id)
            : _assetCtrl.text.trim(),
      );
      await GameContentService.instance.upsertItem(id, item);
      _snack('✓ Kaydedildi: $name');
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadImage() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    if (id.isEmpty) {
      _snack('Önce eşya kodunu girin, sonra görsel yükleyin.');
      return;
    }
    setState(() => _uploadingImage = true);
    try {
      final url = await AdminImageUploadService.instance.pickAndUploadImage(
        folder: 'items',
        entityId: id,
      );
      if (url != null) {
        _assetCtrl.text = url;
        setState(() {});
        _snack('Görsel yüklendi.');
      }
    } catch (e) {
      _snack('Görsel yükleme hatası — ayrıntı için diyalog.');
      if (mounted) {
        await showAdminErrorDialog(context, 'Storage hatası', e);
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    if (!await _confirm('Eşyayı sil', '"$id" silinsin mi?')) return;
    await GameContentService.instance.deleteItem(id);
    _snack('Silindi.');
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _loadFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final item = Item.fromMap({...doc.data(), 'id': doc.id});
    _idCtrl.text = doc.id;
    _nameCtrl.text = item.name;
    _priceCtrl.text = '${item.price}';
    _dmgCtrl.text = '${item.bonusDamage}';
    _levelCtrl.text = '${item.requiredLevel}';
    _critCtrl.text = '${(item.criticalChance * 100).round()}';
    _assetCtrl.text = item.imagePath;
    setState(() {
      _itemType = item.itemType;
      _rarity = item.rarity;
      _shopCurrency = item.shopCurrency;
    });
    _snack('Düzenleniyor: ${item.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Eşya Editörü',
      subtitle: 'Mağazadaki silah, zırh ve iksirleri düzenleyin. Değişiklikler oyunda anında görünür.',
      form: _buildForm(),
      listHeader: Text(
        'Kayıtlı eşyalar',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: _buildList(),
    );
  }

  Widget _buildForm() {
    return AdminFormCard(
      title: 'Yeni eşya veya düzenle',
      primaryLabel: 'Kaydet',
      primaryLoading: _saving,
      onPrimary: _saveItem,
      secondaryLabel: 'Formu temizle',
      onSecondary: _clearForm,
      children: [
        adminTextField(
          controller: _idCtrl,
          label: 'Eşya kodu',
          hint: 'steel_blade',
        ),
        adminTextField(controller: _nameCtrl, label: 'Eşya adı', hint: 'Çelik Bıçak'),
        adminShopCurrencyPicker(
          value: _shopCurrency,
          onChanged: (c) => setState(() => _shopCurrency = c),
        ),
        adminTextField(
          controller: _priceCtrl,
          label: 'Fiyat',
          hint: _shopCurrency == ShopCurrency.diamond ? 'Örn: 50 elmas' : 'Örn: 200 altın',
          keyboardType: TextInputType.number,
        ),
        adminTextField(
          controller: _dmgCtrl,
          label: 'Hasar (DMG)',
          keyboardType: TextInputType.number,
        ),
        adminTextField(
          controller: _levelCtrl,
          label: 'Seviye kilidi',
          keyboardType: TextInputType.number,
        ),
        adminTextField(
          controller: _critCtrl,
          label: 'Kritik şansı (%)',
          keyboardType: TextInputType.number,
        ),
        adminTextField(
          controller: _assetCtrl,
          label: 'Görsel yolu',
          hint: 'assets/... veya https://...',
        ),
        AdminSecondaryButton(
          label: _uploadingImage ? 'Yükleniyor...' : 'Bilgisayardan görsel seç',
          icon: Icons.upload_file_outlined,
          onPressed: _uploadingImage ? null : _uploadImage,
        ),
        const SizedBox(height: 12),
        if (_assetCtrl.text.trim().isNotEmpty)
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
                  imagePath: _assetCtrl.text.trim(),
                  width: 52,
                  height: 52,
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
        adminDropdown<ItemType>(
          value: _itemType,
          label: 'Tür',
          items: ItemType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(_typeLabel(t))))
              .toList(),
          onChanged: (v) => setState(() => _itemType = v ?? ItemType.weapon),
        ),
        adminDropdown<ItemRarity>(
          value: _rarity,
          label: 'Nadirlik',
          items: ItemRarity.values
              .map((r) => DropdownMenuItem(value: r, child: Text(_rarityLabel(r))))
              .toList(),
          onChanged: (v) => setState(() => _rarity = v ?? ItemRarity.common),
        ),
      ],
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: GameContentService.instance.watchItemDocs(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Bağlantı hatası:\n${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!;
        if (docs.isEmpty) {
          return const Center(
            child: Text('Henüz eşya yok.\nSoldan ilk eşyanızı ekleyin.'),
          );
        }
        return ListView.builder(
          shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
          physics: AdminListScrollPhysics.listPhysics(context),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final item = Item.fromMap({...doc.data(), 'id': doc.id});
            return AdminEntryCard(
              title: item.name,
              subtitle:
                  '${item.shopCurrency.formatPrice(item.price)} · DMG ${item.bonusDamage} · Lv ${item.requiredLevel} · ${_rarityLabel(item.rarity)}',
              leading: CircleAvatar(
                child: Text(
                  item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                ),
              ),
              onEdit: () => _loadFromDoc(doc),
              onDelete: () => _deleteItem(doc.id),
            );
          },
        );
      },
    );
  }

  static String _typeLabel(ItemType t) => switch (t) {
        ItemType.weapon => 'Silah',
        ItemType.armor => 'Zırh',
        ItemType.potion => 'İksir',
      };

  static String _rarityLabel(ItemRarity r) => switch (r) {
        ItemRarity.common => 'Sıradan',
        ItemRarity.rare => 'Nadir',
        ItemRarity.epic => 'Epik',
        ItemRarity.legendary => 'Efsanevi',
      };
}
