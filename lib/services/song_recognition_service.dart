import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RecognizedSong {
  final String artist;
  final String title;
  final String? album;
  final String? artworkUrl;
  final String? songLink;

  RecognizedSong({
    required this.artist,
    required this.title,
    this.album,
    this.artworkUrl,
    this.songLink,
  });

  String get fullTitle => '$artist - $title';
}

class SongRecognitionService {
  /// Pobiera ok. 6-8 sekund próbki ze strumienia stacji (MP3/AAC)
  static Future<List<int>?> _captureStreamSample(String streamUrl) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['User-Agent'] = 'RadyjkoON/1.0';

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 8),
      );

      if (streamedResponse.statusCode != 200) {
        client.close();
        return null;
      }

      final buffer = <int>[];
      // Ok. 120 KB to ok. 7-8 sekund przy 128 kbps (idealne dla Shazama)
      const targetBytes = 120 * 1024;
      final completer = Completer<List<int>>();

      late StreamSubscription sub;
      sub = streamedResponse.stream.listen(
        (chunk) {
          buffer.addAll(chunk);
          if (buffer.length >= targetBytes) {
            sub.cancel();
            client.close();
            if (!completer.isCompleted) completer.complete(buffer);
          }
        },
        onError: (e) {
          client.close();
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );

      final audioBytes = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          sub.cancel();
          client.close();
          if (buffer.isNotEmpty) return buffer;
          throw TimeoutException('Przekroczono czas buforowania strumienia');
        },
      );

      if (audioBytes.length < 40 * 1024) {
        return null;
      }
      return audioBytes;
    } catch (e) {
      print('DEBUG [SongRecognitionService] Błąd pobierania strumienia: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Rozpoznaje utwór:
  /// 1. Jeśli podano rapidApiKey -> pyta bazę Shazam (RapidAPI)
  /// 2. Jeśli brak klucza lub błąd -> próbuje awaryjnie AudD
  static Future<RecognizedSong?> recognizeFromStream(
    String streamUrl, {
    String? rapidApiKey,
    String? auddToken,
  }) async {
    final audioBytes = await _captureStreamSample(streamUrl);
    if (audioBytes == null) return null;

    // 1. Próba przez Shazam na RapidAPI (jeśli użytkownik podał klucz)
    if (rapidApiKey != null && rapidApiKey.trim().isNotEmpty) {
      final shazamResult = await _recognizeViaShazam(audioBytes, rapidApiKey.trim());
      if (shazamResult != null) return shazamResult;
    }

    // 2. Fallback przez AudD (np. darmowy test lub token)
    return await _recognizeViaAudd(audioBytes, auddToken);
  }

  /// Zapytanie do bazy Shazam przez RapidAPI (Shazam API Free oraz Shazam Core)
  static Future<RecognizedSong?> _recognizeViaShazam(
    List<int> audioBytes,
    String apiKey,
  ) async {
    // 1. Próba przez Shazam API Free (shazam-api-free.p.rapidapi.com / upload_file)
    try {
      final uri = Uri.parse('https://shazam-api-free.p.rapidapi.com/shazam/recognize/');
      final req = http.MultipartRequest('POST', uri);
      req.headers['X-RapidAPI-Key'] = apiKey;
      req.headers['X-RapidAPI-Host'] = 'shazam-api-free.p.rapidapi.com';
      req.files.add(
        http.MultipartFile.fromBytes('upload_file', audioBytes, filename: 'sample.mp3'),
      );

      final res = await req.send().timeout(const Duration(seconds: 15));
      final respBody = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final parsed = _parseShazamResponse(respBody);
        if (parsed != null) return parsed;
      }
    } catch (e) {
      print('DEBUG [SongRecognitionService] Shazam API Free: $e');
    }

    // 2. Próba przez Shazam Core (shazam-core.p.rapidapi.com / file)
    try {
      final uri = Uri.parse('https://shazam-core.p.rapidapi.com/v1/tracks/recognize');
      final req = http.MultipartRequest('POST', uri);
      req.headers['X-RapidAPI-Key'] = apiKey;
      req.headers['X-RapidAPI-Host'] = 'shazam-core.p.rapidapi.com';
      req.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'sample.mp3'),
      );

      final res = await req.send().timeout(const Duration(seconds: 15));
      final respBody = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final parsed = _parseShazamResponse(respBody);
        if (parsed != null) return parsed;
      }
    } catch (e) {
      print('DEBUG [SongRecognitionService] Shazam Core: $e');
    }

    return null;
  }

  static RecognizedSong? _parseShazamResponse(String respBody) {
    try {
      final data = json.decode(respBody) as Map<String, dynamic>;
      Map<String, dynamic>? track;

      if (data['result'] != null && data['result'] is Map && data['result']['track'] != null) {
        track = data['result']['track'] as Map<String, dynamic>;
      } else if (data['track'] != null && data['track'] is Map) {
        track = data['track'] as Map<String, dynamic>;
      } else if (data['matches'] is List && (data['matches'] as List).isNotEmpty) {
        final firstMatch = data['matches'][0];
        if (firstMatch is Map && firstMatch['track'] != null) {
          track = firstMatch['track'] as Map<String, dynamic>;
        }
      }

      if (track != null) {
        final title = track['title'] as String?;
        final artist = track['subtitle'] as String?;
        String? artwork;
        if (track['images'] != null && track['images']['coverart'] != null) {
          artwork = track['images']['coverart'] as String?;
        }
        if (title != null && artist != null && title.isNotEmpty && artist.isNotEmpty) {
          return RecognizedSong(
            artist: artist.trim(),
            title: title.trim(),
            artworkUrl: artwork,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Zapytanie do bazy AudD
  static Future<RecognizedSong?> _recognizeViaAudd(
    List<int> audioBytes,
    String? token,
  ) async {
    try {
      final effectiveToken = (token != null && token.trim().isNotEmpty) ? token.trim() : 'test';
      final uri = Uri.parse('https://api.audd.io/');
      final req = http.MultipartRequest('POST', uri);
      req.fields['api_token'] = effectiveToken;
      req.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'sample.mp3'),
      );

      final res = await req.send().timeout(const Duration(seconds: 15));
      final respBody = await res.stream.bytesToString();

      if (res.statusCode == 200) {
        final data = json.decode(respBody) as Map<String, dynamic>;
        if (data['status'] == 'success' && data['result'] != null) {
          final result = data['result'] as Map<String, dynamic>;
          final artist = result['artist'] as String?;
          final title = result['title'] as String?;
          if (artist != null && title != null && artist.isNotEmpty && title.isNotEmpty) {
            return RecognizedSong(
              artist: artist.trim(),
              title: title.trim(),
              album: result['album'] as String?,
              songLink: result['song_link'] as String?,
            );
          }
        }
      }
    } catch (e) {
      print('DEBUG [SongRecognitionService] Błąd AudD: $e');
    }
    return null;
  }
}
