import 'package:flutter/material.dart';

import '../../models/premium_package.dart';
import '../../services/admin_image_upload_service.dart';
import '../../services/game_content_service.dart';
import '../../widgets/pixel_asset_image.dart';
import '../widgets/admin_buttons.dart';
import '../widgets/admin_editor_layout.dart';
import '../widgets/admin_entry_card.dart';
import '../widgets/admin_form_card.dart';

class PremiumPackageEditorTab extends StatefulWidget {
  const PremiumPackageEditorTab({super.key});

  @override
  State<PremiumPackageEditorTab> createState() => _PremiumPackageEditorTabState();
}

class _PremiumPackageEditorTabState extends State<PremiumPackageEditorTab> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _diamondCtrl = TextEditingController(text: '500');
  final _priceCtrl = TextEditingController(text: '149.99');
  final _iconCtrl = TextEditingController(
    text: 'assets/images/items/health_potion.png',
  );
  final _currencyCtrl = TextEditingController(text: 'TRY');

  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    _diamondCtrl.dispose();
    _priceCtrl.dispose();
    _iconCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  void _clearForm() {
    _idCtrl.clear();
    _nameCtrl.clear();
    _diamondCtrl.text = '500';
    _priceCtrl.text = '149.99';
    _iconCtrl.text = 'assets/images/items/health_potion.png';
    _currencyCtrl.text = 'TRY';
  }

  Future<void> _uploadIcon() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    setState(() => _uploadingImage = true);
    try {
      final url = await AdminImageUploadService.instance.pickAndUploadImage(
        folder: 'premium',
        entityId: id.isEmpty ? 'package' : id,
      );
      if (url != null) {
        _iconCtrl.text = url;
        setState(() {});
        _snack('İkon yüklendi.');
      }
    } catch (e) {
      _snack('Yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    final id = _idCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = _nameCtrl.text.trim();
    if (id.isEmpty || name.isEmpty) {
      _snack('Paket kodu ve adı gerekli.');
      return;
    }

    setState(() => _saving = true);
    try {
      final pkg = PremiumPackage(
        id: id,
        name: name,
        diamondAmount: int.tryParse(_diamondCtrl.text) ?? 0,
        price: double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0,
        iconPath: _iconCtrl.text.trim(),
        currencyLabel: _currencyCtrl.text.trim().isEmpty
            ? 'TRY'
            : _currencyCtrl.text.trim(),
      );
      await GameContentService.instance.upsertPremiumPackage(id, pkg);
      _snack('✓ Paket kaydedildi: $name');
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
        title: const Text('Paketi sil'),
        content: Text('"$id" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;
    await GameContentService.instance.deletePremiumPackage(id);
    _snack('Silindi.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _load(PremiumPackage p) {
    _idCtrl.text = p.id;
    _nameCtrl.text = p.name;
    _diamondCtrl.text = '${p.diamondAmount}';
    _priceCtrl.text = '${p.price}';
    _iconCtrl.text = p.iconPath;
    _currencyCtrl.text = p.currencyLabel;
    _snack('Düzenleniyor: ${p.name}');
  }

  @override
  Widget build(BuildContext context) {
    return AdminEditorLayout(
      title: 'Elmas Mağazası (IAP)',
      subtitle: 'Gerçek parayla satılacak elmas paketlerini yönetin.',
      form: AdminFormCard(
        title: 'Yeni elmas paketi',
        primaryLabel: 'Paketi kaydet',
        primaryLoading: _saving,
        onPrimary: _save,
        secondaryLabel: 'Formu temizle',
        onSecondary: _clearForm,
        children: [
          adminTextField(controller: _idCtrl, label: 'Paket kodu', hint: 'gem_pouch'),
          adminTextField(
            controller: _nameCtrl,
            label: 'Paket adı',
            hint: 'Kese Dolusu Elmas',
          ),
          adminTextField(
            controller: _diamondCtrl,
            label: 'Elmas miktarı',
            keyboardType: TextInputType.number,
          ),
          adminTextField(
            controller: _priceCtrl,
            label: 'Fiyat',
            hint: '149.99',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          adminTextField(
            controller: _currencyCtrl,
            label: 'Para birimi',
            hint: 'TRY / USD',
          ),
          adminTextField(
            controller: _iconCtrl,
            label: 'Paket ikon yolu',
            hint: 'assets/... veya https://...',
          ),
          AdminSecondaryButton(
            label: _uploadingImage ? 'Yükleniyor...' : 'İkon yükle',
            icon: Icons.upload_file_outlined,
            onPressed: _uploadingImage ? null : _uploadIcon,
          ),
          if (_iconCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            PixelAssetImage(
              imagePath: _iconCtrl.text.trim(),
              width: 48,
              height: 48,
            ),
          ],
        ],
      ),
      listHeader: Text(
        'Premium paketler',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      list: StreamBuilder<List<PremiumPackage>>(
        stream: GameContentService.instance.watchPremiumPackages(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final packages = snapshot.data!;
          if (packages.isEmpty) {
            return const Center(child: Text('Henüz paket yok.'));
          }
          return ListView.builder(
            shrinkWrap: AdminListScrollPhysics.listShrinkWrap(context),
            physics: AdminListScrollPhysics.listPhysics(context),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final p = packages[index];
              return AdminEntryCard(
                title: p.name,
                subtitle:
                    '💎 ${p.diamondAmount} · ${p.formattedPrice}\n${p.iconPath}',
                leading: PixelAssetImage(
                  imagePath: p.iconPath,
                  width: 40,
                  height: 40,
                  placeholderSeed: p.id,
                ),
                onEdit: () => _load(p),
                onDelete: () => _delete(p.id),
              );
            },
          );
        },
      ),
    );
  }
}
