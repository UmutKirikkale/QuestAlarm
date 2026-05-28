import 'package:flutter/material.dart';

/// [AdminEditorLayout] içinde liste kaydırma modunu alt bileşenlere iletir.
class AdminScrollScope extends InheritedWidget {
  const AdminScrollScope({
    super.key,
    required this.listScrollsIndependently,
    required super.child,
  });

  final bool listScrollsIndependently;

  static AdminScrollScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminScrollScope>();
  }

  @override
  bool updateShouldNotify(AdminScrollScope oldWidget) {
    return listScrollsIndependently != oldWidget.listScrollsIndependently;
  }
}
