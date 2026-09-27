import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';

  // Bezpośredni link do pliku version.json na GitHub
  static const String _versionUrl =
      'https://raw.githubusercontent.com/bodziopolska/radyjko/main/version.json';

  // Aktualna wersja aplikacji — zmień przy każdym buildzie
  static const String currentVersion = '1.0.1';
  static const int currentBuild = 2;

  /// Sprawdza, czy jest dostępna nowa wersja.
  /// Zwraca dane aktualizacji lub null jeśli brak.
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_versionUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final latestBuild = data['build'] as int? ?? 0;

        if (latestBuild > currentBuild) {
          return data;
        }
      }
    } catch (_) {
      // Nie blokuj startu aplikacji jeśli sprawdzenie się nie uda
    }
    return null;
  }

  /// Sprawdza aktualizację i pokazuje dialog jeśli jest nowa wersja.
  /// Pomija sprawdzenie jeśli użytkownik kliknął "Pomiń" w ciągu ostatnich 24h.
  static Future<void> checkAndPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSkipped = prefs.getInt('update_skipped_at') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Nie pytaj ponownie przez 24h po kliknięciu "Później"
    if (now - lastSkipped < 24 * 60 * 60 * 1000) return;

    final update = await checkForUpdate();
    if (update == null || !context.mounted) return;

    final strings = AppStrings.of(context);
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
              ? 'Dostępna aktualizacja!'
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
              strings.locale.languageCode == 'pl' ? 'Później' : 'Later',
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
