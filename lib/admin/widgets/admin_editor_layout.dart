import 'package:flutter/material.dart';

import 'admin_scroll_scope.dart';

/// Form + liste düzeni; web ve dar ekranda otomatik uyum, dikey kaydırma.
class AdminEditorLayout extends StatelessWidget {
  const AdminEditorLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.listHeader,
    required this.list,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget listHeader;
  final Widget list;

  static const double _wideBreakpoint = 960;
  static const double _formWidth = 400;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    return AdminScrollScope(
      listScrollsIndependently: wide,
      child: wide ? _buildWide(context) : _buildNarrow(context),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _formWidth,
                  child: SingleChildScrollView(
                    primary: false,
                    child: form,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      listHeader,
                      const SizedBox(height: 12),
                      Expanded(child: list),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return SingleChildScrollView(
      primary: true,
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          Padding(padding: const EdgeInsets.all(16), child: form),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: listHeader,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: list,
          ),
        ],
      ),
    );
  }
}

/// Editör sekmelerindeki [ListView] için kaydırma ayarı.
class AdminListScrollPhysics {
  static ScrollPhysics listPhysics(BuildContext context) {
    final independent =
        AdminScrollScope.maybeOf(context)?.listScrollsIndependently ?? true;
    return independent
        ? const ClampingScrollPhysics()
        : const NeverScrollableScrollPhysics();
  }

  static bool listShrinkWrap(BuildContext context) {
    final independent =
        AdminScrollScope.maybeOf(context)?.listScrollsIndependently ?? true;
    return !independent;
  }
}
