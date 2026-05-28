import 'package:flutter/material.dart';

import '../../models/shop_currency.dart';
import 'admin_buttons.dart';

/// Form alanlarını saran kart.
class AdminFormCard extends StatelessWidget {
  const AdminFormCard({
    super.key,
    required this.title,
    required this.children,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final List<Widget> children;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 20),
            AdminPrimaryButton(
              label: primaryLabel,
              onPressed: onPrimary,
              loading: primaryLoading,
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 8),
              AdminSecondaryButton(
                label: secondaryLabel!,
                onPressed: onSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tutarlı metin alanı.
Widget adminTextField({
  required TextEditingController controller,
  required String label,
  String? hint,
  TextInputType? keyboardType,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget adminDropdown<T>({
  required T value,
  required String label,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

/// Altın / Elmas seçimi — web’de her zaman görünür segmented kontrol.
Widget adminShopCurrencyPicker({
  required ShopCurrency value,
  required ValueChanged<ShopCurrency> onChanged,
  String label = 'Satış para birimi',
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<ShopCurrency>(
          segments: const [
            ButtonSegment(
              value: ShopCurrency.gold,
              label: Text('Altın'),
              icon: Icon(Icons.paid_outlined, size: 18),
            ),
            ButtonSegment(
              value: ShopCurrency.diamond,
              label: Text('Elmas'),
              icon: Icon(Icons.diamond_outlined, size: 18),
            ),
          ],
          selected: {value},
          onSelectionChanged: (set) {
            if (set.isNotEmpty) onChanged(set.first);
          },
        ),
      ],
    ),
  );
}
