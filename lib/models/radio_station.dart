import 'dart:convert';

class RadioStation {
  final String stationUuid;
  final String name;
  final String url;
  final String urlResolved;
  final String homepage;
  final String favicon;
  final String tags;
  final String country;
  final String countryCode;
  final String language;
  final int votes;
  final String codec;
  final int bitrate;
  final int lastCheckOk;
  final int clickCount;
  final int clickTrend;
  final int hls;

  RadioStation({
    required this.stationUuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.countryCode,
    required this.language,
    required this.votes,
    required this.codec,
    required this.bitrate,
    required this.lastCheckOk,
    required this.clickCount,
    required this.clickTrend,
    required this.hls,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      stationUuid: json['stationuuid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Station',
      url: json['url'] as String? ?? '',
      urlResolved: json['url_resolved'] as String? ?? '',
      homepage: json['homepage'] as String? ?? '',
      favicon: json['favicon'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countryCode: json['countrycode'] as String? ?? '',
      language: json['language'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      codec: json['codec'] as String? ?? '',
      bitrate: json['bitrate'] as int? ?? 0,
      lastCheckOk: json['lastcheckok'] as int? ?? 0,
      clickCount: json['clickcount'] as int? ?? 0,
      clickTrend: json['clicktrend'] as int? ?? 0,
      hls: json['hls'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationuuid': stationUuid,
      'name': name,
      'url': url,
      'url_resolved': urlResolved,
      'homepage': homepage,
      'favicon': favicon,
      'tags': tags,
      'country': country,
      'countrycode': countryCode,
      'language': language,
      'votes': votes,
      'codec': codec,
      'bitrate': bitrate,
      'lastcheckok': lastCheckOk,
      'clickcount': clickCount,
      'clicktrend': clickTrend,
      'hls': hls,
    };
  }

  /// Returns the best available stream URL (resolved preferred over raw).
  String get streamUrl =>
      urlResolved.isNotEmpty ? urlResolved : url;

  /// Whether the station was online at last check.
  bool get isOnline => lastCheckOk == 1;

  /// Returns a list of tag strings.
  List<String> get tagList =>
      tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

  /// Returns a country flag emoji from the country code.
  String get countryFlag {
    if (countryCode.length != 2) return '🌐';
    final int first = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int second = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  /// Returns the best available favicon. Falls back to Clearbit Logo API using the homepage domain.
  String get bestFavicon {
    if (favicon.isNotEmpty) {
      return favicon;
    }
    if (homepage.isNotEmpty) {
      try {
        final uri = Uri.parse(homepage);
        if (uri.host.isNotEmpty) {
          return 'https://logo.clearbit.com/${uri.host}';
        }
      } catch (_) {
        // Ignore parse errors
      }
    }
    return '';
  }

  /// Serializes the station to a JSON string for local storage.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes a station from a JSON string.
  static RadioStation fromJsonString(String jsonString) =>
      RadioStation.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadioStation &&
          runtimeType == other.runtimeType &&
          stationUuid == other.stationUuid;

  @override
  int get hashCode => stationUuid.hashCode;
}
