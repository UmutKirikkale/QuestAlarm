import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/live_ops_guard_service.dart';
import '../services/user_document_sync_service.dart';

/// Oturum açıkken global LiveOps dinleyicilerini başlatır.
class LiveOpsGuardHost extends StatefulWidget {
  const LiveOpsGuardHost({super.key, required this.child});

  final Widget? child;

  @override
  State<LiveOpsGuardHost> createState() => _LiveOpsGuardHostState();
}

class _LiveOpsGuardHostState extends State<LiveOpsGuardHost> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = AuthService.instance.authStateChanges.listen(_onAuthChanged);
    _onAuthChanged(AuthService.instance.currentUser);
  }

  void _onAuthChanged(User? user) {
    if (user != null) {
      UserDocumentSyncService.instance.attach(user.uid);
      LiveOpsGuardService.instance.start(user.uid);
    } else {
      LiveOpsGuardService.instance.stop();
      UserDocumentSyncService.instance.detach();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    LiveOpsGuardService.instance.stop();
    UserDocumentSyncService.instance.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
