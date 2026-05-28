import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/admin_firebase_auth.dart';
import '../../services/admin_image_upload_service.dart';

/// Üst şerit — Storage / Auth durumu ve hızlı test.
class AdminFirebaseStatusBar extends StatefulWidget {
  const AdminFirebaseStatusBar({super.key});

  @override
  State<AdminFirebaseStatusBar> createState() => _AdminFirebaseStatusBarState();
}

String _shortUid(String? uid) {
  if (uid == null || uid.isEmpty) return '?';
  return uid.length > 8 ? '${uid.substring(0, 8)}…' : uid;
}

class _AdminFirebaseStatusBarState extends State<AdminFirebaseStatusBar> {
  String? _probeResult;
  bool _probing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runProbe());
  }

  Future<void> _runProbe() async {
    if (_probing) return;
    setState(() {
      _probing = true;
      _probeResult = null;
    });
    final result = await AdminImageUploadService.instance.probeAccess();
    if (!mounted) return;
    setState(() {
      _probeResult = result;
      _probing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authed = AdminFirebaseAuth.isSignedIn;
    final probe = _probeResult;
    final storageOk = probe != null && probe.contains('OK');

    return Material(
      color: const Color(0xFF1A1D28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              authed ? Icons.verified_user : Icons.person_off_outlined,
              size: 18,
              color: authed ? const Color(0xFF00E5A0) : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                authed
                    ? 'Auth: anonim (${_shortUid(AdminFirebaseAuth.currentUser?.uid)})'
                    : 'Auth yok — Storage kuralları açıksa yükleme yine çalışır',
                style: const TextStyle(fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_probing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                storageOk ? Icons.cloud_done : Icons.cloud_off,
                size: 18,
                color: storageOk ? const Color(0xFF00E5A0) : Colors.redAccent,
              ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _probing ? null : _runProbe,
              child: const Text('Storage test'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hata metnini kopyalanabilir diyalogda gösterir.
Future<void> showAdminErrorDialog(
  BuildContext context,
  String title,
  Object error,
) async {
  final text = error.toString();
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(text, style: const TextStyle(fontSize: 12)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hata metni kopyalandı')),
            );
          },
          child: const Text('Kopyala'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
