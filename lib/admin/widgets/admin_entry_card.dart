import 'package:flutter/material.dart';

/// Kayıt listesi için tek satırlık kart.
class AdminEntryCard extends StatelessWidget {
  const AdminEntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.onEdit,
    this.onDelete,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Düzenle',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 22),
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Sil',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 22,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: onDelete,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
