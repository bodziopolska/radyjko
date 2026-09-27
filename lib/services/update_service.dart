import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class UpdateService {
  // BezpoĹ›redni link do pliku version.json na GitHub
  static const String _versionUrl =
      'https://raw.githubusercontent.com/bodziopolska/radyjko/main/version.json';

  // Aktualna wersja aplikacji â€” zmieĹ„ przy kaĹĽdym buildzie
  static const String currentVersion = '1.0.2';
  static const int currentBuild = 3;

  /// Sprawdza, czy jest dostÄ™pna nowa wersja.
  /// Zwraca dane aktualizacji lub null jeĹ›li brak.
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      print('DEBUG [UpdateService]: Rozpoczynam sprawdzanie aktualizacji z $_versionUrl');
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 10));

      print('DEBUG [UpdateService]: Kod odpowiedzi HTTP: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latestBuild = data['build'] as int? ?? 0;
        print('DEBUG [UpdateService]: Wersja z neta: $latestBuild, Moja wersja: $currentBuild');

        if (latestBuild > currentBuild) {
          print('DEBUG [UpdateService]: Znaleziono nowszÄ… wersjÄ™!');
          return data;
        } else {
          print('DEBUG [UpdateService]: Brak nowszej wersji.');
        }
      }
    } catch (e, stack) {
      print('DEBUG [UpdateService]: BĹÄ„D przy pobieraniu aktualizacji: $e');
      print(stack);
    }
    return null;
  }

  /// Sprawdza aktualizacjÄ™ i pokazuje dialog jeĹ›li jest nowa wersja.
  /// Pomija sprawdzenie jeĹ›li uĹĽytkownik kliknÄ…Ĺ‚ "PomiĹ„" w ciÄ…gu ostatnich 24h.
  static Future<void> checkAndPrompt(BuildContext context) async {
    print('DEBUG [UpdateService]: WywoĹ‚ano checkAndPrompt()');
    final prefs = await SharedPreferences.getInstance();
    final lastSkipped = prefs.getInt('update_skipped_at') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Nie pytaj ponownie przez 24h po klikniÄ™ciu "PĂłĹşniej" (zakomentowane na czas testĂłw)
    // if (now - lastSkipped < 24 * 60 * 60 * 1000) return;

    final update = await checkForUpdate();
    if (update == null) {
      print('DEBUG [UpdateService]: checkForUpdate zwrĂłciĹ‚o null, przerywam.');
      return;
    }
    if (!context.mounted) {
      print('DEBUG [UpdateService]: context.mounted == false, przerywam.');
      return;
    }

    print('DEBUG [UpdateService]: PokazujÄ™ dialog aktualizacji!');

    // UĹĽywamy read() zamiast watch(), bo jesteĹ›my poza metodÄ… build()
    final locale = context.read<SettingsProvider>().locale;
    final strings = AppStrings.forLocale(locale);
    final theme = Theme.of(context);
    final latestVersion = update['version'] as String? ?? '?';
    final changelog = update['changelog'] as String? ?? '';
    final apkUrl = update['apk_url'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.system_update_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          strings.locale.languageCode == 'pl'
              ? 'DostÄ™pna aktualizacja!'
              : 'Update available!',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.locale.languageCode == 'pl'
                  ? 'Nowa wersja: $latestVersion\nTwoja wersja: $currentVersion'
                  : 'New version: $latestVersion\nYour version: $currentVersion',
              style: theme.textTheme.bodyMedium,
            ),
            if (changelog.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                strings.locale.languageCode == 'pl'
                    ? 'Co nowego:'
                    : 'What\'s new:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                changelog,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setInt(
                  'update_skipped_at', DateTime.now().millisecondsSinceEpoch);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              strings.locale.languageCode == 'pl' ? 'PĂłĹşniej' : 'Later',
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: Text(
              strings.locale.languageCode == 'pl' ? 'Aktualizuj' : 'Update',
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (apkUrl.isNotEmpty) {
                final uri = Uri.parse(apkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
