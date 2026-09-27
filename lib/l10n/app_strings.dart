import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

/// Holds all UI strings for both Polish and English.
class AppStrings {
  final String appName;
  final String browse;
  final String favorites;
  final String settings;
  final String searchHint;
  final String popular;
  final String trending;
  final String results;
  final String filters;
  final String sortBy;
  final String sortPopularity;
  final String sortName;
  final String sortBitrate;
  final String sortVotes;
  final String country;
  final String allCountries;
  final String language;
  final String allLanguages;
  final String genre;
  final String allGenres;
  final String codec;
  final String minBitrate;
  final String onlyWorking;
  final String hideOffline;
  final String apply;
  final String reset;
  final String noResults;
  final String tryChangingFilters;
  final String loadFailed;
  final String checkConnection;
  final String tryAgain;
  final String noFavorites;
  final String addFavoritesHint;
  final String removedFromFavorites;
  final String undo;
  final String buffering;
  final String paused;
  final String connectionError;
  final String unknown;
  final String theme;
  final String themeLight;
  final String themeDark;
  final String themeSystem;
  final String languageSetting;
  final String about;
  final String version;
  final String apiSource;
  final String stationPlayError;
  final String stationConnectError;
  final String defaultCountry;
  final String noStationSelected;
  final String stopped;
  final String searchInSpotify;
  final String setStationLogo;
  final String logoUrl;
  final String removeLogo;
  final String cancel;
  final String save;
  final String enableItunesCovers;
  final String disableItunesCovers;
  final String swipeToRemoveHint;
  final String expandPlayer;
  final String stopPlayback;
  final String filterStations;
  final String playStation;
  final String stopStation;
  final String addToFavorites;
  final String removeFromFavoritesAction;
  
  // Przechowuje jÄ™zyk uĹĽyty do zaĹ‚adowania tych napisĂłw, przydatne do zewnÄ™trznych widgetĂłw.
  final Locale locale;

  const AppStrings({
    required this.appName,
    required this.browse,
    required this.favorites,
    required this.settings,
    required this.searchHint,
    required this.popular,
    required this.trending,
    required this.results,
    required this.filters,
    required this.sortBy,
    required this.sortPopularity,
    required this.sortName,
    required this.sortBitrate,
    required this.sortVotes,
    required this.country,
    required this.allCountries,
    required this.language,
    required this.allLanguages,
    required this.genre,
    required this.allGenres,
    required this.codec,
    required this.minBitrate,
    required this.onlyWorking,
    required this.hideOffline,
    required this.apply,
    required this.reset,
    required this.noResults,
    required this.tryChangingFilters,
    required this.loadFailed,
    required this.checkConnection,
    required this.tryAgain,
    required this.noFavorites,
    required this.addFavoritesHint,
    required this.removedFromFavorites,
    required this.undo,
    required this.buffering,
    required this.paused,
    required this.connectionError,
    required this.unknown,
    required this.theme,
    required this.themeLight,
    required this.themeDark,
    required this.themeSystem,
    required this.languageSetting,
    required this.about,
    required this.version,
    required this.apiSource,
    required this.stationPlayError,
    required this.stationConnectError,
    required this.defaultCountry,
    required this.noStationSelected,
    required this.stopped,
    required this.searchInSpotify,
    required this.setStationLogo,
    required this.logoUrl,
    required this.removeLogo,
    required this.cancel,
    required this.save,
    required this.enableItunesCovers,
    required this.disableItunesCovers,
    required this.swipeToRemoveHint,
    required this.expandPlayer,
    required this.stopPlayback,
    required this.filterStations,
    required this.playStation,
    required this.stopStation,
    required this.addToFavorites,
    required this.removeFromFavoritesAction,
    required this.locale,
  });

  static const pl = AppStrings(
    appName: 'RadyjkoON',
    browse: 'Przeglądaj',
    favorites: 'Ulubione',
    settings: 'Opcje',
    searchHint: 'Szukaj stacji radiowych...',
    popular: '🔥 Popularne',
    trending: '📈 Trending',
    results: '🔍 Wyniki',
    filters: 'Filtry',
    sortBy: 'Sortuj wg',
    sortPopularity: 'Popularność',
    sortName: 'Nazwa',
    sortBitrate: 'Bitrate',
    sortVotes: 'Głosy',
    country: 'Kraj',
    allCountries: 'Wszystkie kraje',
    language: 'Język',
    allLanguages: 'Wszystkie języki',
    genre: 'Gatunek',
    allGenres: 'Wszystkie gatunki',
    codec: 'Codec',
    minBitrate: 'Minimalny bitrate',
    onlyWorking: 'Tylko działające stacje',
    hideOffline: 'Ukryj stacje offline',
    apply: 'Zastosuj',
    reset: 'Resetuj',
    noResults: 'Brak wyników',
    tryChangingFilters: 'Spróbuj zmienić filtry lub wyszukiwanie',
    loadFailed: 'Nie udało się załadować stacji',
    checkConnection: 'Sprawdź połączenie z internetem',
    tryAgain: 'Spróbuj ponownie',
    noFavorites: 'Brak ulubionych stacji',
    addFavoritesHint: 'Dodaj stacje do ulubionych klikając ❤️',
    removedFromFavorites: 'Usunięto z ulubionych',
    undo: 'Cofnij',
    buffering: 'Buforowanie...',
    paused: 'Pauza',
    connectionError: 'Błąd połączenia',
    unknown: 'Nieznany',
    theme: 'Motyw',
    themeLight: 'Jasny',
    themeDark: 'Ciemny',
    themeSystem: 'Systemowy',
    languageSetting: 'Język aplikacji',
    about: 'Informacje',
    version: 'Wersja',
    apiSource: 'Źródło danych',
    stationPlayError: 'Nie udało się odtworzyć stacji',
    stationConnectError: 'Nie udało się połączyć ze stacją',
    defaultCountry: 'Kraj domyślny',
    noStationSelected: 'Brak wybranej stacji',
    stopped: 'Zatrzymano',
    searchInSpotify: 'Szukaj w Spotify',
    setStationLogo: 'Ustaw logo stacji',
    logoUrl: 'URL logo',
    removeLogo: 'Usuń logo',
    cancel: 'Anuluj',
    save: 'Zapisz',
    enableItunesCovers: 'Włącz okładki iTunes',
    disableItunesCovers: 'Wyłącz okładki iTunes',
    swipeToRemoveHint: 'Przesuń stację w lewo, aby usunąć',
    expandPlayer: 'Otwórz odtwarzacz',
    stopPlayback: 'Zatrzymaj odtwarzanie',
    filterStations: 'Filtruj stacje',
    playStation: 'Odtwórz stację',
    stopStation: 'Zatrzymaj stację',
    addToFavorites: 'Dodaj do ulubionych',
    removeFromFavoritesAction: 'Usuń z ulubionych',
    locale: Locale('pl'),
  );

  static const en = AppStrings(
    appName: 'RadyjkoON',
    browse: 'Browse',
    favorites: 'Favorites',
    settings: 'Settings',
    searchHint: 'Search radio stations...',
    popular: 'đź”Ą Popular',
    trending: 'đź“ Trending',
    results: 'đź”Ť Results',
    filters: 'Filters',
    sortBy: 'Sort by',
    sortPopularity: 'Popularity',
    sortName: 'Name',
    sortBitrate: 'Bitrate',
    sortVotes: 'Votes',
    country: 'Country',
    allCountries: 'All countries',
    language: 'Language',
    allLanguages: 'All languages',
    genre: 'Genre',
    allGenres: 'All genres',
    codec: 'Codec',
    minBitrate: 'Min bitrate',
    onlyWorking: 'Only working stations',
    hideOffline: 'Hide offline stations',
    apply: 'Apply',
    reset: 'Reset',
    noResults: 'No results',
    tryChangingFilters: 'Try changing filters or search query',
    loadFailed: 'Failed to load stations',
    checkConnection: 'Check your internet connection',
    tryAgain: 'Try again',
    noFavorites: 'No favorite stations',
    addFavoritesHint: 'Add stations to favorites by tapping âť¤ď¸Ź',
    removedFromFavorites: 'Removed from favorites',
    undo: 'Undo',
    buffering: 'Buffering...',
    paused: 'Paused',
    connectionError: 'Connection error',
    unknown: 'Unknown',
    theme: 'Theme',
    themeLight: 'Light',
    themeDark: 'Dark',
    themeSystem: 'System',
    languageSetting: 'App language',
    about: 'About',
    version: 'Version',
    apiSource: 'Data source',
    stationPlayError: 'Failed to play station',
    stationConnectError: 'Failed to connect to station',
    defaultCountry: 'Default country',
    noStationSelected: 'No station selected',
    stopped: 'Stopped',
    searchInSpotify: 'Search on Spotify',
    setStationLogo: 'Set station logo',
    logoUrl: 'Logo URL',
    removeLogo: 'Remove logo',
    cancel: 'Cancel',
    save: 'Save',
    enableItunesCovers: 'Enable iTunes covers',
    disableItunesCovers: 'Disable iTunes covers',
    swipeToRemoveHint: 'Swipe a station left to remove it',
    expandPlayer: 'Open player',
    stopPlayback: 'Stop playback',
    filterStations: 'Filter stations',
    playStation: 'Play station',
    stopStation: 'Stop station',
    addToFavorites: 'Add to favorites',
    removeFromFavoritesAction: 'Remove from favorites',
    locale: Locale('en'),
  );

  /// Returns strings for the given locale.
  static AppStrings of(BuildContext context) {
    final locale = context.watch<SettingsProvider>().locale;
    return forLocale(locale);
  }

  static AppStrings forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return en;
      case 'pl':
      default:
        return pl;
    }
  }
}

