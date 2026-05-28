import 'package:flutter/material.dart';

import 'tabs/class_editor_tab.dart';
import 'tabs/item_editor_tab.dart';
import 'tabs/map_editor_tab.dart';
import 'tabs/event_editor_tab.dart';
import 'tabs/media_library_tab.dart';
import 'tabs/premium_package_editor_tab.dart';
import 'tabs/god_mode_tab.dart';
import 'tabs/monster_editor_tab.dart';
import 'tabs/global_settings_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'widgets/admin_firebase_status_bar.dart';
import 'widgets/live_activity_terminal.dart';

/// Web ve masaüstü için Oyun Editörü.
class AdminCmsApp extends StatelessWidget {
  const AdminCmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF00E5A0);
    return MaterialApp(
      title: 'QuestAlarm Oyun Editörü',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: true,
        physics: const ClampingScrollPhysics(),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF12141C),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0B10),
        visualDensity: VisualDensity.standard,
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1D28),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF222633),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: Color(0xFF12141C),
          indicatorColor: Color(0x3300E5A0),
          selectedIconTheme: IconThemeData(color: seed),
          selectedLabelTextStyle: TextStyle(
            color: seed,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: TextStyle(fontSize: 11),
        ),
      ),
      home: const _AdminShell(),
    );
  }
}

class _AdminShell extends StatefulWidget {
  const _AdminShell();

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _index = 0;

  static const _destinations = [
    (icon: Icons.shopping_bag_outlined, label: 'Eşyalar', short: 'Mağaza eşyaları'),
    (icon: Icons.people_outline, label: 'Sınıflar', short: 'Kahraman sınıfları'),
    (icon: Icons.map_outlined, label: 'Haritalar', short: 'Sabah zindanları'),
    (icon: Icons.photo_library_outlined, label: 'Medya', short: 'Storage galeri'),
    (icon: Icons.celebration_outlined, label: 'Etkinlikler', short: 'Canlı etkinlikler'),
    (icon: Icons.diamond_outlined, label: 'Elmas IAP', short: 'Premium paketler'),
    (icon: Icons.admin_panel_settings_outlined, label: 'God Mode', short: 'Oyuncu mod'),
    (icon: Icons.pest_control_outlined, label: 'Canavarlar', short: 'Monster edit'),
    (icon: Icons.public_outlined, label: 'Küresel', short: 'LiveOps ayar'),
    (icon: Icons.leaderboard_outlined, label: 'Liderlik', short: 'Sıralama mod'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final showSideFeed = MediaQuery.sizeOf(context).width >= 1280;
    final showBottomFeed = !showSideFeed && MediaQuery.sizeOf(context).width >= 720;

    final tabBody = switch (_index) {
      0 => const ItemEditorTab(),
      1 => const ClassEditorTab(),
      2 => const MapEditorTab(),
      3 => const MediaLibraryTab(),
      4 => const EventEditorTab(),
      5 => const PremiumPackageEditorTab(),
      6 => const GodModeTab(),
      7 => const MonsterEditorTab(),
      8 => const GlobalSettingsTab(),
      9 => const LeaderboardTab(),
      _ => const ItemEditorTab(),
    };

    final content = showSideFeed
        ? Row(
            children: [
              Expanded(child: tabBody),
              const SizedBox(width: 8),
              const SizedBox(
                width: 300,
                child: LiveActivityTerminal(),
              ),
            ],
          )
        : Column(
            children: [
              Expanded(child: tabBody),
              if (showBottomFeed)
                const SizedBox(
                  height: 200,
                  child: LiveActivityTerminal(),
                ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuestAlarm LiveOps Merkezi'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(
                Icons.cloud_done_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: const Text('Firestore canlı'),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminFirebaseStatusBar(),
          Expanded(
            child: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  minExtendedWidth: 180,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(
                          d.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : Column(
              children: [
                NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        label: d.label,
                      ),
                  ],
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
