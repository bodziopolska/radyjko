import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final strings = AppStrings.forLocale(settings.locale);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.settings),
      ),
      body: ListView(
        children: [
          // Language section
          _buildSectionHeader(theme, strings.languageSetting),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pl', label: Text('Polski')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (newSelection) {
                settings.setLocale(Locale(newSelection.first));
              },
            ),
          ),
          const Divider(),

          // Default country section
          _buildSectionHeader(theme, strings.defaultCountry),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              value: settings.defaultCountry,
              items: [
                DropdownMenuItem(value: '', child: Text(strings.allCountries)),
                const DropdownMenuItem(value: 'Poland', child: Text('Polska')),
                const DropdownMenuItem(value: 'United Kingdom', child: Text('United Kingdom')),
                const DropdownMenuItem(value: 'United States', child: Text('United States')),
                const DropdownMenuItem(value: 'Germany', child: Text('Niemcy')),
                const DropdownMenuItem(value: 'France', child: Text('Francja')),
                const DropdownMenuItem(value: 'Spain', child: Text('Hiszpania')),
                const DropdownMenuItem(value: 'Italy', child: Text('WĹ‚ochy')),
              ],
              onChanged: (val) {
                if (val != null) settings.setDefaultCountry(val);
              },
            ),
          ),
          const Divider(),

          // Theme section
          _buildSectionHeader(theme, strings.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(strings.themeSystem),
                    icon: const Icon(Icons.brightness_auto)),
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(strings.themeLight),
                    icon: const Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(strings.themeDark),
                    icon: const Icon(Icons.dark_mode)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                settings.setThemeMode(newSelection.first);
              },
            ),
          ),
          const Divider(),

          // Song Recognition Section (Shazam / RapidAPI)
          _buildSectionHeader(theme, 'Rozpoznawanie muzyki'),
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: const Text('Klucz RapidAPI (Shazam)'),
            subtitle: Text(
              settings.rapidApiKey != null
                  ? 'Klucz skonfigurowany (${settings.rapidApiKey!.substring(0, (settings.rapidApiKey!.length > 6 ? 6 : settings.rapidApiKey!.length))}...)'
                  : 'DomyĹ›lny (kliknij, aby podaÄ‡ swĂłj darmowy klucz RapidAPI Shazam)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRapidApiKeyDialog(context, settings),
          ),
          const Divider(),

          // Cloud Account Section
          _buildSectionHeader(theme, 'Konto w chmurze'),
          if (auth.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: Text(auth.user?.displayName ?? 'Zalogowano', style: theme.textTheme.titleMedium),
              subtitle: Text(auth.user?.email ?? '', style: theme.textTheme.bodySmall),
              trailing: TextButton(
                onPressed: () => auth.signOut(),
                child: const Text('Wyloguj'),
              ),
            )
          else
            ListTile(
              leading: const Icon(Icons.cloud_sync, color: Colors.blue),
              title: Text('Zapisuj ulubione w chmurze', style: theme.textTheme.titleMedium),
              subtitle: Text('Zaloguj siÄ™, aby odzyskaÄ‡ stacje na nowym telefonie', style: theme.textTheme.bodySmall),
              trailing: auth.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton.icon(
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Zaloguj z Google'),
                      onPressed: () => auth.signInWithGoogle(),
                    ),
            ),
          const Divider(),

          // About section
          _buildSectionHeader(theme, strings.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.appName),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text('Wersja ' + snapshot.data!.version + ' (Build ' + snapshot.data!.buildNumber + ')');
                }
                return const Text('Wersja 1.0.4 Beta (Build 5)');
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_queue),
            title: Text(strings.apiSource),
            subtitle: const Text('radio-browser.info'),
          ),
        ],
      ),
    );
  }

  void _showRapidApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.rapidApiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klucz RapidAPI (Shazam)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Podaj swĂłj darmowy klucz z RapidAPI (Shazam Core), aby rozpoznawaÄ‡ utwory bezpoĹ›rednio w bazie Shazama.\n\nDarmowy pakiet na rapidapi.com odnawia pulÄ™ darmowych zapytaĹ„ co miesiÄ…c.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Klucz X-RapidAPI-Key',
                border: OutlineInputBorder(),
                hintText: 'np. 9f4a8b...',
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://rapidapi.com/tipsters/api/shazam-core');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (_) {}
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('OtwĂłrz stronÄ™ RapidAPI Shazam'),
            ),
          ],
        ),
        actions: [
          if (settings.rapidApiKey != null)
            TextButton(
              onPressed: () {
                settings.setRapidApiKey(null);
                Navigator.pop(ctx);
              },
              child: const Text('WyczyĹ›Ä‡'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              settings.setRapidApiKey(text.isNotEmpty ? text : null);
              Navigator.pop(ctx);
            },
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


