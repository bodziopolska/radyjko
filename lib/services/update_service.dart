import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class UpdateService {
  // Bezpośredni link do pliku version.json na GitHub
  static const String _versionUrl =
      'https://raw.githubusercontent.com/bodziopolska/radyjko/main/version.json';

  // Aktualna wersja aplikacji — zmień przy każdym buildzie
  static const String currentVersion = '1.0.4 Beta';
  static const int currentBuild = 5;

  /// Sprawdza, czy jest dostępna nowa wersja.
  /// Zwraca dane aktualizacji lub null jeśli brak.
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

        int myBuild = currentBuild;
        try {
          final info = await PackageInfo.fromPlatform();
          myBuild = int.tryParse(info.buildNumber) ?? currentBuild;
        } catch (_) {}

        print('DEBUG [UpdateService]: Wersja z neta: $latestBuild, Moja wersja: $myBuild');

        if (latestBuild > myBuild) {
          print('DEBUG [UpdateService]: Znaleziono nowszą wersję!');
          return data;
        } else {
          print('DEBUG [UpdateService]: Brak nowszej wersji.');
        }
      }
    } catch (e, stack) {
      print('DEBUG [UpdateService]: BŁĄD przy pobieraniu aktualizacji: $e');
      print(stack);
    }
    return null;
  }

  /// Sprawdza aktualizację i pokazuje dialog jeśli jest nowa wersja.
  static Future<void> checkAndPrompt(BuildContext context, {bool showFeedbackIfLatest = false}) async {
    print('DEBUG [UpdateService]: Wywołano checkAndPrompt()');
    final prefs = await SharedPreferences.getInstance();

    final update = await checkForUpdate();
    if (!context.mounted) return;

    if (update == null) {
      if (showFeedbackIfLatest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikacja jest aktualna! Masz najnowszą wersję.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    print('DEBUG [UpdateService]: Pokazuję dialog aktualizacji!');

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
