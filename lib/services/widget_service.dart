import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'player_service.dart';
import '../theme/pixel_text.dart';
import '../theme/quest_theme.dart';

enum LiveWidgetStatus { happy, sad, neutral }

/// Ana ekran widget'ını Flutter'dan render ederek günceller.
class WidgetService {
  WidgetService._();

  static final WidgetService instance = WidgetService._();

  static const String _imageKey = 'qa_widget_image';
  static const String _providerName = 'QuestAlarmWidgetProvider';
  static const String _qualifiedProviderName =
      'com.questalarm.quest_alarm.QuestAlarmWidgetProvider';

  Future<void> updateLiveWidget({
    required LiveWidgetStatus status,
  }) async {
    final player = await PlayerService.instance.loadPlayer();
    final mood = _moodData(status);

    await _renderFlutterToImage(
      key: _imageKey,
      widget: _QuestLiveWidgetCard(
        emoji: mood.emoji,
        statusText: mood.statusText,
        warningText: mood.warningText,
        streak: player.streak,
      ),
    );

    await HomeWidget.saveWidgetData<String>('qa_widget_status', status.name);
    await HomeWidget.saveWidgetData<int>('qa_widget_streak', player.streak);
    await HomeWidget.updateWidget(
      name: _providerName,
      qualifiedAndroidName: _qualifiedProviderName,
    );
  }

  /// `renderFlutterToImage` için servis içi sarmalayıcı.
  Future<String> _renderFlutterToImage({
    required String key,
    required Widget widget,
  }) async {
    // home_widget paketindeki güncel API: renderFlutterWidget.
    return HomeWidget.renderFlutterWidget(
      widget,
      key: key,
      logicalSize: const Size(320, 180),
      pixelRatio: Platform.isAndroid ? 3.0 : 2.0,
    );
  }

  ({String emoji, String statusText, String warningText}) _moodData(
    LiveWidgetStatus status,
  ) {
    return switch (status) {
      LiveWidgetStatus.happy => (
          emoji: '(^_^)',
          statusText: 'Kahraman Hazir!',
          warningText: 'Zafer Serisi Devam',
        ),
      LiveWidgetStatus.sad => (
          emoji: '(x_x)',
          statusText: 'Kahraman Yarali!',
          warningText: 'Koy Tehlikede!',
        ),
      LiveWidgetStatus.neutral => (
          emoji: '(-_-)',
          statusText: 'Kahraman Uykuda',
          warningText: 'Alarm Bekleniyor',
        ),
    };
  }
}

class _QuestLiveWidgetCard extends StatelessWidget {
  const _QuestLiveWidgetCard({
    required this.emoji,
    required this.statusText,
    required this.warningText,
    required this.streak,
  });

  final String emoji;
  final String statusText;
  final String warningText;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1428), Color(0xFF1C2E52)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QUEST ALARM',
            style: pixelTextStyle(fontSize: 14, color: QuestTheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A16),
                    border: Border.all(color: const Color(0xFF9FAAC6), width: 2),
                  ),
                  child: Text(
                    emoji,
                    style: pixelTextStyle(fontSize: 26, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        statusText,
                        style: pixelTextStyle(fontSize: 12, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        warningText,
                        style: pixelTextStyle(fontSize: 11, color: QuestTheme.secondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seri: $streak',
                        style: pixelTextStyle(fontSize: 12, color: const Color(0xFFFF8C42)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
