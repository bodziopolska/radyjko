import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';
import '../services/radio_api_service.dart';

enum StationSort { popularity, name, bitrate, votes }

enum StationCategory { search, top, trending }

class RadioProvider extends ChangeNotifier {
  final RadioApiService _api = RadioApiService();

  // Station data
  List<RadioStation> _stations = [];
  List<RadioStation> get stations => _stations;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _hasMore = true;
  bool get hasMore => _hasMore;

  String? _error;
  String? get error => _error;

  // Current category
  StationCategory _category = StationCategory.top;
  StationCategory get category => _category;

  // Search & filter state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? _selectedCountry;
  String? get selectedCountry => _selectedCountry;

  String? _selectedCountryCode;
  String? get selectedCountryCode => _selectedCountryCode;

  String? _selectedLanguage;
  String? get selectedLanguage => _selectedLanguage;

  String? _selectedTag;
  String? get selectedTag => _selectedTag;

  String? _selectedCodec;
  String? get selectedCodec => _selectedCodec;

  int _minBitrate = 0;
  int get minBitrate => _minBitrate;

  bool _hidebroken = true;
  bool get hidebroken => _hidebroken;

  StationSort _sort = StationSort.popularity;
  StationSort get sort => _sort;

  // Filter option lists
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> get countries => _countries;

  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> get tags => _tags;

  List<Map<String, dynamic>> _languages = [];
  List<Map<String, dynamic>> get languages => _languages;

  // Favorites
  Set<String> _favoriteIds = {};
  List<RadioStation> _favoriteStations = [];
  List<RadioStation> get favoriteStations => _favoriteStations;

  // Per-station settings
  Set<String> _itunesDisabledIds = {};
  Map<String, String> _customLogos = {};

  // Pagination
  int _offset = 0;
  static const int _pageSize = 100;

  /// Initialize — load top stations and filter options.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Always start fresh on Popular tab — don't load old filters
    // Users can re-apply filters via the filter sheet
    _selectedCountry = null;
    _selectedCountryCode = null;
    _selectedLanguage = null;
    _selectedTag = null;
    _selectedCodec = null;
    _minBitrate = 0;
    _hidebroken = true;
    _sort = StationSort.popularity;
    _category = StationCategory.top;

    await _loadFavorites();
    _loadStationSettings(prefs);
    await Future.wait([
      loadStations(),
      _loadFilterOptions(),
    ]);

    // Update the country code once countries are loaded
    if (_selectedCountry != null && _countries.isNotEmpty) {
      final match = _countries.firstWhere(
        (c) => c['name'] == _selectedCountry,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        _selectedCountryCode = match['iso_3166_1'] as String?;
      }
    }
  }

  /// Changes the active station category tab.
  void setCategory(StationCategory category) {
    if (_category == category) return;
    _category = category;
    _offset = 0;
    _hasMore = true;
    notifyListeners();
    loadStations();
  }

  /// Sets the search query and reloads stations.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _offset = 0;
    _hasMore = true;
    notifyListeners();
    if (query.isNotEmpty) {
      _category = StationCategory.search;
    }
    loadStations();
  }

  /// Applies filter settings.
  void applyFilters({
    String? country,
    String? countryCode,
    String? language,
    String? tag,
    String? codec,
    int minBitrate = 0,
    bool hidebroken = true,
    StationSort sort = StationSort.popularity,
  }) {
    _selectedCountry = country;
    _selectedCountryCode = countryCode;
    _selectedLanguage = language;
    _selectedTag = tag;
    _selectedCodec = codec;
    _minBitrate = minBitrate;
    _hidebroken = hidebroken;
    _sort = sort;
    _offset = 0;
    _hasMore = true;
    _category = StationCategory.search;
    _saveFilters();
    notifyListeners();
    loadStations();
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedCountry != null) prefs.setString('filter_country', _selectedCountry!);
    else prefs.remove('filter_country');
    
    if (_selectedCountryCode != null) prefs.setString('filter_countryCode', _selectedCountryCode!);
    else prefs.remove('filter_countryCode');

    if (_selectedLanguage != null) prefs.setString('filter_language', _selectedLanguage!);
    else prefs.remove('filter_language');

    if (_selectedTag != null) prefs.setString('filter_tag', _selectedTag!);
    else prefs.remove('filter_tag');

    if (_selectedCodec != null) prefs.setString('filter_codec', _selectedCodec!);
    else prefs.remove('filter_codec');

    prefs.setInt('filter_minBitrate', _minBitrate);
    prefs.setBool('filter_hidebroken', _hidebroken);
    prefs.setString('filter_sort', _sort.name);
  }

  /// Resets all filters to defaults.
  void resetFilters() {
    _selectedCountry = null;
    _selectedCountryCode = null;
    _selectedLanguage = null;
    _selectedTag = null;
    _selectedCodec = null;
    _minBitrate = 0;
    _hidebroken = true;
    _sort = StationSort.popularity;
    _searchQuery = '';
    _offset = 0;
    _hasMore = true;
    _category = StationCategory.top;
    _saveFilters();
    notifyListeners();
    loadStations();
  }

  /// Whether any filters are active.
  bool get hasActiveFilters =>
      _selectedCountry != null ||
      _selectedLanguage != null ||
      _selectedTag != null ||
      _selectedCodec != null ||
      _minBitrate > 0;

  /// Loads the stations list (initial or refresh).
  Future<void> loadStations() async {
    _isLoading = true;
    _error = null;
    _offset = 0;
    notifyListeners();

    try {
      List<RadioStation> result;

      switch (_category) {
        case StationCategory.top:
          if (hasActiveFilters || _searchQuery.isNotEmpty) {
            result = await _searchWithFilters();
          } else {
            final prefs = await SharedPreferences.getInstance();
            final defaultCountry = prefs.getString('defaultCountry');
            result = await _api.getTopStations(limit: _pageSize, country: defaultCountry?.isNotEmpty == true ? defaultCountry : null);
          }
        case StationCategory.trending:
          if (hasActiveFilters || _searchQuery.isNotEmpty) {
            result = await _searchWithFilters();
          } else {
            final prefs = await SharedPreferences.getInstance();
            final defaultCountry = prefs.getString('defaultCountry');
            result = await _api.getTrendingStations(limit: _pageSize, country: defaultCountry?.isNotEmpty == true ? defaultCountry : null);
          }
        case StationCategory.search:
          result = await _searchWithFilters();
      }

      _stations = result;
      _hasMore = result.length >= _pageSize;
      _offset = result.length;
    } catch (e) {
      _error = e.toString();
      _stations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads more stations for infinite scroll.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _searchWithFilters(offset: _offset);
      _stations.addAll(result);
      _hasMore = result.length >= _pageSize;
      _offset += result.length;
    } catch (e) {
      // Silently fail on load more — keep existing data.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<List<RadioStation>> _searchWithFilters({int? offset}) async {
    String orderParam;
    switch (_sort) {
      case StationSort.popularity:
        orderParam = 'clickcount';
      case StationSort.name:
        orderParam = 'name';
      case StationSort.bitrate:
        orderParam = 'bitrate';
      case StationSort.votes:
        orderParam = 'votes';
    }

    return _api.searchStations(
      name: _searchQuery.isNotEmpty ? _searchQuery : null,
      country: _selectedCountry,
      countryCode: _selectedCountryCode,
      language: _selectedLanguage,
      tag: _selectedTag,
      codec: _selectedCodec,
      bitrateMin: _minBitrate > 0 ? _minBitrate : null,
      hidebroken: _hidebroken,
      order: orderParam,
      reverse: _sort != StationSort.name,
      offset: offset ?? 0,
      limit: _pageSize,
    );
  }

  /// Loads filter dropdown options from API.
  Future<void> _loadFilterOptions() async {
    try {
      _countries = await _api.getCountries();
    } catch (_) {}
    try {
      _tags = await _api.getTags(limit: 150);
    } catch (_) {}
    try {
      _languages = await _api.getLanguages();
    } catch (_) {}
    notifyListeners();
  }

  // ============ FAVORITES ============

  bool isFavorite(String stationUuid) => _favoriteIds.contains(stationUuid);

  Future<void> toggleFavorite(RadioStation station) async {
    if (_favoriteIds.contains(station.stationUuid)) {
      _favoriteIds.remove(station.stationUuid);
      _favoriteStations
          .removeWhere((s) => s.stationUuid == station.stationUuid);
    } else {
      _favoriteIds.add(station.stationUuid);
      _favoriteStations.add(station);
    }
    notifyListeners();
    await _saveFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> stored = prefs.getStringList('favorites') ?? [];
    _favoriteStations = stored.map(RadioStation.fromJsonString).toList();
    _favoriteIds = _favoriteStations.map((s) => s.stationUuid).toSet();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data =
        _favoriteStations.map((s) => s.toJsonString()).toList();
    await prefs.setStringList('favorites', data);
  }

  // ============ PER-STATION SETTINGS ============

  void _loadStationSettings(SharedPreferences prefs) {
    _itunesDisabledIds = (prefs.getStringList('itunes_disabled') ?? []).toSet();
    final logoList = prefs.getStringList('custom_logos') ?? [];
    _customLogos = {};
    for (final entry in logoList) {
      final sep = entry.indexOf('|');
      if (sep > 0) {
        _customLogos[entry.substring(0, sep)] = entry.substring(sep + 1);
      }
    }
  }

  Future<void> _saveStationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('itunes_disabled', _itunesDisabledIds.toList());
    final logoList = _customLogos.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList('custom_logos', logoList);
  }

  bool isItunesDisabled(String stationUuid) => _itunesDisabledIds.contains(stationUuid);

  Future<void> toggleItunesForStation(String stationUuid) async {
    if (_itunesDisabledIds.contains(stationUuid)) {
      _itunesDisabledIds.remove(stationUuid);
    } else {
      _itunesDisabledIds.add(stationUuid);
    }
    notifyListeners();
    await _saveStationSettings();
  }

  String? getCustomLogo(String stationUuid) => _customLogos[stationUuid];

  Future<void> setCustomLogo(String stationUuid, String? url) async {
    if (url == null || url.isEmpty) {
      _customLogos.remove(stationUuid);
    } else {
      _customLogos[stationUuid] = url;
    }
    notifyListeners();
    await _saveStationSettings();
  }
}
