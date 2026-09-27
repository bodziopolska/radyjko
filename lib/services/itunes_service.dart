import 'dart:convert';
import 'package:http/http.dart' as http;

class ItunesService {
  static Future<String?> getArtwork(String songQuery) async {
    if (songQuery.trim().isEmpty) return null;
    try {
      final url = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent(songQuery)}&entity=song&limit=1');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          final artworkUrl = data['results'][0]['artworkUrl100'] as String?;
          if (artworkUrl != null) {
            return artworkUrl.replaceAll('100x100bb', '600x600bb');
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
