import 'package:flutter/material.dart';

import '../../models/live_log_entry.dart';
import '../../services/live_log_service.dart';

/// Canlı olay terminali — siber retro yeşil/siyah.
class LiveActivityTerminal extends StatelessWidget {
  const LiveActivityTerminal({super.key});

  static const Color _neon = Color(0xFF00E5A0);
  static const Color _bg = Color(0xFF050608);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: _neon.withValues(alpha: 0.45), width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: _neon.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _neon.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(color: _neon.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16, color: _neon),
                const SizedBox(width: 8),
                Text(
                  'CANLI AKIŞ',
                  style: TextStyle(
                    color: _neon,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LiveLogEntry>>(
              stream: LiveLogService.instance.watchLogs(limit: 60),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Log hatası',
                      style: _lineStyle(color: Colors.redAccent),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Text(
                      'Bağlanıyor...',
                      style: _lineStyle(color: _neon.withValues(alpha: 0.6)),
                    ),
                  );
                }
                final logs = snapshot.data!;
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz olay yok.\nMobil oyundan aktivite bekleniyor.',
                      textAlign: TextAlign.center,
                      style: _lineStyle(color: _neon.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${log.formattedTime()} ${log.message}',
                        style: _lineStyle(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _lineStyle({Color? color}) {
    return TextStyle(
      fontFamily: 'monospace',
      fontSize: 11,
      height: 1.35,
      color: color ?? _neon,
    );
  }
}
