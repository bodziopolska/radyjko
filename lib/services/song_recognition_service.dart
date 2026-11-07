import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

class RecognitionResult {
  final RecognizedSong? song;
  final String? errorMessage;

  bool get isSuccess => song != null;

  RecognitionResult.success(this.song) : errorMessage = null;
  RecognitionResult.error(this.errorMessage) : song = null;
}

class SongRecognitionService {
  /// Pobiera ok. 8-10 sekund czystego strumienia stacji (MP3/AAC)
  static Future<List<int>?> _captureStreamSample(String streamUrl) async {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true;
    client.connectionTimeout = const Duration(seconds: 8);

    try {
      final req = await client.getUrl(Uri.parse(streamUrl));
      req.headers.set('User-Agent', 'RadyjkoON/1.0');
      req.headers.set('Icy-MetaData', '0'); // Wyłącz wstrzykiwanie napisów ICY do strumienia audio
      final res = await req.close().timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) {
        client.close(force: true);
        return null;
      }

      final buffer = <int>[];
      // Ok. 180 KB to ok. 10-12 sekund przy 128 kbps
      const targetBytes = 180 * 1024;
      final completer = Completer<List<int>>();

      late StreamSubscription sub;
      sub = res.listen(
        (chunk) {
          buffer.addAll(chunk);
          if (buffer.length >= targetBytes) {
            sub.cancel();
            client.close(force: true);
            if (!completer.isCompleted) completer.complete(buffer);
          }
        },
        onError: (e) {
          client.close(force: true);
          if (!completer.isCompleted) completer.completeError(e);
        },
        cancelOnError: true,
      );

      final audioBytes = await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          sub.cancel();
          client.close(force: true);
          if (buffer.length > 50 * 1024) return buffer;
          throw TimeoutException('Przekroczono czas buforowania');
        },
      );

      if (audioBytes.length < 40 * 1024) {
        return null;
      }
      return audioBytes;
    } catch (e) {
      print('DEBUG [SongRecognitionService] Błąd capture: $e');
      client.close(force: true);
      return null;
    }
  }

  /// Główna metoda rozpoznawania utworu
  static Future<RecognitionResult> recognizeFromStream(
    String streamUrl, {
    String? rapidApiKey,
  }) async {
    if (rapidApiKey == null || rapidApiKey.trim().isEmpty) {
      return RecognitionResult.error(
        'Brak klucza API! Wejdź w Ustawienia -> Klucz RapidAPI (Shazam) i wklej swój darmowy klucz.',
      );
    }

    final audioBytes = await _captureStreamSample(streamUrl);
    if (audioBytes == null) {
      return RecognitionResult.error('Nie udało się pobrać próbki dźwięku ze strumienia stacji.');
    }

    return await _recognizeViaShazam(audioBytes, rapidApiKey.trim());
  }

  /// Zapytanie do bazy Shazam (shazam-api-free.p.rapidapi.com)
  static Future<RecognitionResult> _recognizeViaShazam(
    List<int> audioBytes,
    String apiKey,
  ) async {
    try {
      final cleanedKey = apiKey.trim().replaceAll('"', '').replaceAll("'", "");
      final uri = Uri.parse('https://shazam-api-free.p.rapidapi.com/shazam/recognize/');
      final req = http.MultipartRequest('POST', uri);
      req.headers['X-RapidAPI-Key'] = cleanedKey;
      req.headers['X-RapidAPI-Host'] = 'shazam-api-free.p.rapidapi.com';
      req.files.add(
        http.MultipartFile.fromBytes(
          'upload_file',
          audioBytes,
          filename: 'sample.mp3',
          contentType: MediaType('audio', 'mpeg'),
        ),
      );

      final streamedRes = await req.send().timeout(const Duration(seconds: 15));
      final respBody = await streamedRes.stream.bytesToString();

      print('DEBUG [Shazam API] Status: ${streamedRes.statusCode}');
      print('DEBUG [Shazam API] Body: $respBody');

      if (streamedRes.statusCode == 401 || streamedRes.statusCode == 403) {
        return RecognitionResult.error(
          'Błąd RapidAPI (${streamedRes.statusCode}): Nieprawidłowy klucz lub brak aktywnej darmowej subskrypcji "Shazam API free" na RapidAPI.',
        );
      }

      if (streamedRes.statusCode == 429) {
        return RecognitionResult.error('Błąd RapidAPI (429): Wyczerpano limit zapytań lub zbyt częste zapytania.');
      }

      if (streamedRes.statusCode == 200) {
        final parsed = _parseShazamResponse(respBody);
        if (parsed != null) {
          return RecognitionResult.success(parsed);
        } else {
          return RecognitionResult.error('Shazam nie rozpoznał utworu (może trwają reklamy lub audycja).');
        }
      }

      return RecognitionResult.error('Błąd serwera RapidAPI: status ${streamedRes.statusCode}');
    } catch (e) {
      return RecognitionResult.error('Błąd połączenia z Shazam: $e');
    }
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
}
