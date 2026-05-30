import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/settings/settings_store.dart';
import 'core/theme/app_theme.dart';
import 'data/db/app_database.dart';
import 'features/dashboard/dashboard_store.dart';
import 'features/feed/feed_store.dart';
import 'features/notes/notes_store.dart';
import 'features/tasks/tasks_store.dart';
import 'features/wishlist/wishlist_store.dart';
import 'services/local_notifications_service.dart';
import 'ui/splash_screen.dart';

class WishlistApp extends StatelessWidget {
  const WishlistApp({super.key});

  static Future<void> bootstrap() async {
    await AppDatabase.instance.init();
    await LocalNotificationsService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore()),
        ChangeNotifierProvider(create: (_) => WishlistStore()..load()),
        ChangeNotifierProvider(create: (_) => NotesStore()..load()),
        ChangeNotifierProvider(create: (_) => TasksStore()..load()),
        ChangeNotifierProxyProvider2<WishlistStore, TasksStore, DashboardStore>(
          create: (_) => DashboardStore(),
          update: (_, wishlist, tasks, dashboard) =>
              (dashboard ?? DashboardStore())..recompute(wishlist, tasks),
        ),
        ChangeNotifierProvider(create: (_) => FeedStore()..loadCached()),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) => MaterialApp(
          title: "Mikisho's Wish",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

