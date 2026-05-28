import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_navigator.dart';
import '../screens/maintenance_screen.dart';
import 'global_settings_service.dart';
import 'user_document_sync_service.dart';

/// Bakım modu ve ban — uygulama açıkken anlık kilit ekranı.
class LiveOpsGuardService {
  LiveOpsGuardService._();

  static final LiveOpsGuardService instance = LiveOpsGuardService._();

  StreamSubscription? _settingsSub;
  StreamSubscription<UserDocumentSnapshot>? _userSub;

  bool _maintenanceMode = false;
  bool _isBanned = false;
  bool _lockNavigated = false;
  String? _uid;

  void start(String uid) {
    if (_uid == uid && _settingsSub != null) return;
    stop();
    _uid = uid;
    _lockNavigated = false;

    _settingsSub = GlobalSettingsService.instance.watchSettings().listen(
      (settings) {
        _maintenanceMode = settings.maintenanceMode;
        _evaluateLock();
      },
      onError: (Object e) => debugPrint('LiveOpsGuard settings: $e'),
    );

    if (UserDocumentSyncService.instance.isAttached) {
      _isBanned = UserDocumentSyncService.instance.latest.isBanned;
      _evaluateLock();
    }

    _userSub = UserDocumentSyncService.instance.stream.listen(
      (snap) {
        _isBanned = snap.isBanned;
        _evaluateLock();
      },
      onError: (Object e) => debugPrint('LiveOpsGuard user: $e'),
    );
  }

  void stop() {
    _settingsSub?.cancel();
    _settingsSub = null;
    _userSub?.cancel();
    _userSub = null;
    _uid = null;
    _maintenanceMode = false;
    _isBanned = false;
    _lockNavigated = false;
  }

  void _evaluateLock() {
    if (_lockNavigated) return;

    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    if (_maintenanceMode) {
      _lockNavigated = true;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LiveOpsLockScreen.maintenance(),
        ),
        (_) => false,
      );
      return;
    }

    if (_isBanned) {
      _lockNavigated = true;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LiveOpsLockScreen.banned(),
        ),
        (_) => false,
      );
    }
  }
}
