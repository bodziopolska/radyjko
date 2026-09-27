import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/app_strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final strings = AppStrings.forLocale(settings.locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.settings,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Language section
          _buildSectionHeader(theme, strings.languageSetting),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pl', label: Text('Polski 🇵🇱')),
                ButtonSegment(value: 'en', label: Text('English 🇬🇧')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (Set<String> newSelection) {
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
                const DropdownMenuItem(value: 'Italy', child: Text('Włochy')),
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

          // About section
          _buildSectionHeader(theme, strings.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.appName),
            subtitle: Text('${strings.version} 1.0.0'),
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
