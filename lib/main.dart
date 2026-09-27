import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'providers/radio_provider.dart';
import 'providers/player_provider.dart';
import 'providers/settings_provider.dart';
import 'services/audio_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

late RadioAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure audio session for background playback
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Initialize AudioService for background playback
  _audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.radyjkoon.channel.audio',
      androidNotificationChannelName: 'Odtwarzanie Radia',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_notification',
    ),
  );

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(RadyjkoOnApp(settingsProvider: settingsProvider));
}

class RadyjkoOnApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const RadyjkoOnApp({super.key, required this.settingsProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => RadioProvider()),
        ChangeNotifierProvider(create: (_) => PlayerProvider(_audioHandler)),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'RadyjkoON',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: settings.themeMode,
            locale: settings.locale,
            // Fallback localization delegates could be added here if using material localizations
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}






