import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_image_upload_service.dart';
import '../widgets/admin_buttons.dart';

class MediaLibraryTab extends StatefulWidget {
  const MediaLibraryTab({super.key});

  @override
  State<MediaLibraryTab> createState() => _MediaLibraryTabState();
}

class _MediaLibraryTabState extends State<MediaLibraryTab> {
  String _folder = 'items';
  late Future<List<StoredImageFile>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<StoredImageFile>> _load() {
    return AdminImageUploadService.instance.listImages(_folder);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _delete(StoredImageFile file) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Görseli sil'),
        content: Text('${file.name} kalıcı olarak silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AdminImageUploadService.instance.deleteImageByPath(file.path);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Görsel silindi.')),
    );
    _refresh();
  }

  Future<void> _copyUrl(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL panoya kopyalandı.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoredImageFile>>(
      future: _future,
      builder: (context, snapshot) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Medya Kütüphanesi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'items', label: Text('Eşyalar')),
                            ButtonSegment(value: 'maps', label: Text('Haritalar')),
                          ],
                          selected: {_folder},
                          onSelectionChanged: (selection) {
                            final next = selection.first;
                            if (next == _folder) return;
                            setState(() {
                              _folder = next;
                              _future = _load();
                            });
                          },
                        ),
                        IconButton(
                          tooltip: 'Yenile',
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Storage klasörü: $_folder/',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot.hasError)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Hata: ${snapshot.error}')),
              )
            else if (!snapshot.hasData)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.data!.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Bu klasörde henüz görsel yok.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisExtent: 268,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final file = snapshot.data![index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    file.downloadUrl,
                                    fit: BoxFit.cover,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(
                                      color: Color(0x33222222),
                                      child: Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AdminCompactButton(
                                      label: 'URL',
                                      icon: Icons.link,
                                      onPressed: () =>
                                          _copyUrl(file.downloadUrl),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Sil',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _delete(file),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
