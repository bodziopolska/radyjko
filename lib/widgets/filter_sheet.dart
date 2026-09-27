import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/radio_provider.dart';
import '../l10n/app_strings.dart';

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCountry;
  String? _selectedCountryCode;
  String? _selectedLanguage;
  String? _selectedTag;
  String? _selectedCodec;
  double _minBitrate = 0;
  bool _hidebroken = true;
  StationSort _sort = StationSort.popularity;

  static const List<String> _codecs = [
    'MP3',
    'AAC',
    'AAC+',
    'OGG',
    'FLAC',
    'WMA',
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<RadioProvider>();
    _selectedCountry = provider.selectedCountry;
    _selectedCountryCode = provider.selectedCountryCode;
    _selectedLanguage = provider.selectedLanguage;
    _selectedTag = provider.selectedTag;
    _selectedCodec = provider.selectedCodec;
    _minBitrate = provider.minBitrate.toDouble();
    _hidebroken = provider.hidebroken;
    _sort = provider.sort;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final provider = context.watch<RadioProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Scrollable filter options
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Center(
                      child: Text(
                        strings.filters,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sort by
                    Text(strings.sortBy, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: StationSort.values.map((sort) {
                        return ChoiceChip(
                          label: Text(_sortLabel(sort, strings)),
                          selected: _sort == sort,
                          onSelected: (selected) {
                            if (selected) setState(() => _sort = sort);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Country dropdown
                    Text(strings.country, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildCountryDropdown(provider, theme, strings),
                    const SizedBox(height: 20),

                    // Language dropdown
                    Text(strings.language, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildLanguageDropdown(provider, theme, strings),
                    const SizedBox(height: 20),

                    // Tag/Genre dropdown
                    Text(strings.genre, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _buildTagDropdown(provider, theme, strings),
                    const SizedBox(height: 20),

                    // Codec chips
                    Text(strings.codec, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _codecs.map((codec) {
                        return FilterChip(
                          label: Text(codec),
                          selected: _selectedCodec == codec,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCodec = selected ? codec : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Min bitrate slider
                    Text(
                      '${strings.minBitrate}: ${_minBitrate.toInt()} kbps',
                      style: theme.textTheme.titleSmall,
                    ),
                    Slider(
                      value: _minBitrate,
                      min: 0,
                      max: 320,
                      divisions: 16,
                      label: '${_minBitrate.toInt()} kbps',
                      onChanged: (value) {
                        setState(() => _minBitrate = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Hide broken switch
                    SwitchListTile(
                      title: Text(strings.onlyWorking),
                      subtitle: Text(strings.hideOffline),
                      value: _hidebroken,
                      onChanged: (value) {
                        setState(() => _hidebroken = value);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // Sticky action buttons — always visible at the bottom
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.reset),
                      onPressed: () {
                        provider.resetFilters();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(strings.apply),
                      onPressed: () {
                        provider.applyFilters(
                          country: _selectedCountry,
                          countryCode: _selectedCountryCode,
                          language: _selectedLanguage,
                          tag: _selectedTag,
                          codec: _selectedCodec,
                          minBitrate: _minBitrate.toInt(),
                          hidebroken: _hidebroken,
                          sort: _sort,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountryDropdown(RadioProvider provider, ThemeData theme, AppStrings strings) {
    final countries = provider.countries
        .where((c) =>
            (c['name'] as String?) != null &&
            (c['name'] as String).isNotEmpty)
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    final hasSelected = countries.any((c) => c['name'] == _selectedCountry);

    return DropdownButtonFormField<String>(
      value: hasSelected ? _selectedCountry : null,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: strings.allCountries,
        suffixIcon: _selectedCountry != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() {
                    _selectedCountry = null;
                    _selectedCountryCode = null;
                  });
                },
              )
            : null,
      ),
      items: countries.map((c) {
        final name = c['name'] as String;
        final count = c['stationcount'] as int? ?? 0;
        return DropdownMenuItem<String>(
          value: name,
          child: Text('$name ($count)', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          // Find corresponding country code.
          if (value != null) {
            final match = countries.firstWhere(
              (c) => c['name'] == value,
              orElse: () => <String, dynamic>{},
            );
            _selectedCountryCode =
                match['iso_3166_1'] as String? ?? '';
          } else {
            _selectedCountryCode = null;
          }
        });
      },
    );
  }

  Widget _buildLanguageDropdown(RadioProvider provider, ThemeData theme, AppStrings strings) {
    final languages = provider.languages
        .where((l) =>
            (l['name'] as String?) != null &&
            (l['name'] as String).isNotEmpty)
        .toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    final hasSelected = languages.any((l) => l['name'] == _selectedLanguage);

    return DropdownButtonFormField<String>(
      value: hasSelected ? _selectedLanguage : null,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: strings.allLanguages,
        suffixIcon: _selectedLanguage != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() => _selectedLanguage = null);
                },
              )
            : null,
      ),
      items: languages.take(50).map((l) {
        final name = l['name'] as String;
        final count = l['stationcount'] as int? ?? 0;
        return DropdownMenuItem<String>(
          value: name,
          child: Text('$name ($count)', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedLanguage = value);
      },
    );
  }

  Widget _buildTagDropdown(RadioProvider provider, ThemeData theme, AppStrings strings) {
    final tags = provider.tags
        .where((t) =>
            (t['name'] as String?) != null &&
            (t['name'] as String).isNotEmpty)
        .toList();

    return DropdownButtonFormField<String>(
      value: _selectedTag,
      isExpanded: true,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: strings.allGenres,
        suffixIcon: _selectedTag != null
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  setState(() => _selectedTag = null);
                },
              )
            : null,
      ),
      items: tags.take(80).map((t) {
        final name = t['name'] as String;
        final count = t['stationcount'] as int? ?? 0;
        return DropdownMenuItem<String>(
          value: name,
          child: Text('$name ($count)', overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedTag = value);
      },
    );
  }

  String _sortLabel(StationSort sort, AppStrings strings) {
    switch (sort) {
      case StationSort.popularity:
        return strings.sortPopularity;
      case StationSort.name:
        return strings.sortName;
      case StationSort.bitrate:
        return strings.sortBitrate;
      case StationSort.votes:
        return strings.sortVotes;
    }
  }
}


