import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/storage_service.dart';
import '../theme/quest_theme.dart';

/// İlk açılışta batarya ve arka plan izinlerini toplayan retro RPG kurulum ekranı.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _overlayGranted = false;
  bool _batteryGranted = false;
  bool _autoStartOk = false;
  bool _autoStartOpened = false;

  bool get _allPermissionsGranted =>
      _overlayGranted && _batteryGranted && _autoStartOk;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissionStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatuses();
    }
  }

  Future<void> _refreshPermissionStatuses() async {
    final overlay = await Permission.systemAlertWindow.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    final autoStartAvailable = await isAutoStartAvailable;
    final autoStartSatisfied =
        autoStartAvailable != true || _autoStartOpened;

    if (!mounted) return;
    setState(() {
      _overlayGranted = overlay;
      _batteryGranted = battery;
      _autoStartOk = autoStartSatisfied;
    });
  }

  Future<void> _requestOverlayPermission() async {
    await Permission.systemAlertWindow.request();
    await _refreshPermissionStatuses();
  }

  Future<void> _requestBatteryOptimization() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _refreshPermissionStatuses();
  }

  Future<void> _openAutoStartSettings() async {
    final available = await isAutoStartAvailable;
    if (available != true) {
      if (!mounted) return;
      setState(() => _autoStartOk = true);
      return;
    }

    final opened = await getAutoStartPermission();
    if (opened) {
      _autoStartOpened = true;
    }
    await _refreshPermissionStatuses();
  }

  Future<void> _completeSetup() async {
    if (!_allPermissionsGranted) return;

    await StorageService.instance.completePermissionsSetup();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed('/initial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QuestTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuestTitleBanner(),
              const SizedBox(height: 24),
              _QuestTaskRow(
                label: 'Tam Ekran İzni Ver',
                completed: _overlayGranted,
                onPressed: _requestOverlayPermission,
              ),
              const SizedBox(height: 12),
              _QuestTaskRow(
                label: 'Pil Kısıtlamasını Kaldır',
                completed: _batteryGranted,
                onPressed: _requestBatteryOptimization,
              ),
              const SizedBox(height: 12),
              _QuestTaskRow(
                label: 'Otomatik Başlatmayı Aç',
                completed: _autoStartOk,
                onPressed: _openAutoStartSettings,
              ),
              const Spacer(),
              AbsorbPointer(
                absorbing: !_allPermissionsGranted,
                child: _RetroPixelButton(
                  label: 'Maceraya Başla (Devam Et)',
                  onPressed: _completeSetup,
                  backgroundColor: _allPermissionsGranted
                      ? QuestTheme.primary
                      : QuestTheme.surfaceVariant,
                  foregroundColor: _allPermissionsGranted
                      ? QuestTheme.background
                      : QuestTheme.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestTitleBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: QuestTheme.surface,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        children: [
          Text(
            'GÖREV: İZİNLER',
            style: _pixelTextStyle(fontSize: 12, color: QuestTheme.secondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Alarmın çalışması için bu görevleri\ntamamlamalısın, Kahraman!',
            textAlign: TextAlign.center,
            style: _pixelTextStyle(fontSize: 16, color: QuestTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _QuestTaskRow extends StatelessWidget {
  const _QuestTaskRow({
    required this.label,
    required this.completed,
    required this.onPressed,
  });

  final String label;
  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _QuestStatusBadge(completed: completed),
        const SizedBox(width: 12),
        Expanded(
          child: _RetroPixelButton(
            label: label,
            onPressed: onPressed,
            backgroundColor:
                completed ? QuestTheme.surfaceVariant : QuestTheme.surface,
            foregroundColor:
                completed ? QuestTheme.primary : QuestTheme.onBackground,
          ),
        ),
      ],
    );
  }
}

class _QuestStatusBadge extends StatelessWidget {
  const _QuestStatusBadge({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? QuestTheme.primary : QuestTheme.surfaceVariant,
        border: Border.all(
          color: completed ? QuestTheme.primary : Colors.white,
          width: 3,
        ),
      ),
      child: Text(
        completed ? '✓' : '○',
        style: _pixelTextStyle(
          fontSize: 18,
          color: completed ? QuestTheme.background : QuestTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _RetroPixelButton extends StatefulWidget {
  const _RetroPixelButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = QuestTheme.primary,
    this.foregroundColor = QuestTheme.background,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<_RetroPixelButton> createState() => _RetroPixelButtonState();
}

class _RetroPixelButtonState extends State<_RetroPixelButton> {
  bool _isPressed = false;

  static const _borderWidth = 3.0;
  static const _pressOffset = 3.0;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? _pressOffset : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Transform.translate(
        offset: Offset(offset, offset),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: Border.all(color: Colors.white, width: _borderWidth),
            boxShadow: _isPressed
                ? null
                : const [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(_pressOffset, _pressOffset),
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: _pixelTextStyle(
              fontSize: 14,
              color: widget.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _pixelTextStyle({
  required double fontSize,
  Color color = QuestTheme.onBackground,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontSize: fontSize,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: 1,
  );
}
