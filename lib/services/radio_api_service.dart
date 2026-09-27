import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/radio_station.dart';

class RadioApiService {
  static const String _baseUrl = 'https://de1.api.radio-browser.info';
  static const String _userAgent = 'RadyjkoON/1.0';

  static final Map<String, String> _headers = {
    'User-Agent': _userAgent,
    'Content-Type': 'application/json',
  };

  /// Searches stations with advanced filters.
  Future<List<RadioStation>> searchStations({
    String? name,
    String? country,
    String? countryCode,
    String? language,
    String? tag,
    String? codec,
    int? bitrateMin,
    int? bitrateMax,
    bool hidebroken = true,
    String order = 'clickcount',
    bool reverse = true,
    int offset = 0,
    int limit = 30,
  }) async {
    final Map<String, String> params = {
      'hidebroken': hidebroken.toString(),
      'order': order,
      'reverse': reverse.toString(),
      'offset': offset.toString(),
      'limit': limit.toString(),
    };

    if (name != null && name.isNotEmpty) params['name'] = name;
    if (country != null && country.isNotEmpty) params['country'] = country;
    if (countryCode != null && countryCode.isNotEmpty) {
      params['countrycode'] = countryCode;
    }
    if (language != null && language.isNotEmpty) params['language'] = language;
    if (tag != null && tag.isNotEmpty) params['tag'] = tag;
    if (codec != null && codec.isNotEmpty) params['codec'] = codec;
    if (bitrateMin != null) params['bitrateMin'] = bitrateMin.toString();
    if (bitrateMax != null) params['bitrateMax'] = bitrateMax.toString();

    final uri = Uri.parse('$_baseUrl/json/stations/search')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return _processStations(data);
    } else {
      throw Exception('Failed to search stations: ${response.statusCode}');
    }
  }

  /// Gets top stations by votes.
  Future<List<RadioStation>> getTopStations({int limit = 100, String? country}) async {
    return searchStations(
      order: 'votes',
      reverse: true,
      limit: limit,
      country: country,
    );
  }

  /// Gets trending stations (by recent clicks).
  Future<List<RadioStation>> getTrendingStations({int limit = 100, String? country}) async {
    return searchStations(
      order: 'clicktrend',
      reverse: true,
      limit: limit,
      country: country,
    );
  }
  
  List<RadioStation> _processStations(List<dynamic> data) {
    final allStations = data
        .map((json) => RadioStation.fromJson(json as Map<String, dynamic>))
        .toList();

    final Map<String, RadioStation> uniqueStations = {};
    for (final station in allStations) {
      String key = station.name.trim().toLowerCase();
      if (key.startsWith('radio ')) {
        key = key.substring(6).trim();
      }
      
      if (uniqueStations.containsKey(key)) {
        final existing = uniqueStations[key]!;
        final hasFavicon = station.favicon.isNotEmpty || station.homepage.isNotEmpty;
        final existingHasFavicon = existing.favicon.isNotEmpty || existing.homepage.isNotEmpty;
        
        if (hasFavicon && !existingHasFavicon) {
          uniqueStations[key] = station;
        } else if (hasFavicon == existingHasFavicon && station.bitrate > existing.bitrate) {
          uniqueStations[key] = station;
        }
      } else {
        uniqueStations[key] = station;
      }
    }
    return uniqueStations.values.toList();
  }

  /// Gets available countries with station counts.
  Future<List<Map<String, dynamic>>> getCountries() async {
    final uri = Uri.parse('$_baseUrl/json/countries')
        .replace(queryParameters: {'hidebroken': 'true'});
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get countries: ${response.statusCode}');
    }
  }

  /// Gets available tags/genres with station counts.
  Future<List<Map<String, dynamic>>> getTags({int limit = 100}) async {
    final uri = Uri.parse('$_baseUrl/json/tags').replace(queryParameters: {
      'hidebroken': 'true',
      'order': 'stationcount',
      'reverse': 'true',
      'limit': limit.toString(),
    });
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get tags: ${response.statusCode}');
    }
  }

  /// Gets available languages with station counts.
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final uri = Uri.parse('$_baseUrl/json/languages')
        .replace(queryParameters: {'hidebroken': 'true'});
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get languages: ${response.statusCode}');
    }
  }

  /// Registers a click for the station (helps with popularity tracking).
  Future<void> clickStation(String stationUuid) async {
    final uri = Uri.parse('$_baseUrl/json/url/$stationUuid');
    try {
      await http.get(uri, headers: _headers);
    } catch (_) {
      // Fire and forget — don't crash the app if click tracking fails.
    }
  }
}
