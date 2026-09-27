import 'dart:io';

void main() {
  final file = File('lib/providers/player_provider.dart');
  var content = file.readAsStringSync();

  // Replace pause() method
  content = content.replaceFirst(
    "Future<void> pause() => _handler.pause();\r\n  Future<void> resume() => _handler.play();\r\n\r\n  Future<void> stop() async {\r\n    await _handler.stop();\r\n    _currentStation = null;\r\n    _isPlaying = false;\r\n    _isBuffering = false;\r\n    _updateTile();\r\n    notifyListeners();\r\n  }",
    "Future<void> pause() async {\r\n    await _handler.pause();\r\n    _isPlaying = false;\r\n    _updateTile();\r\n    notifyListeners();\r\n  }\r\n\r\n  Future<void> resume() => _handler.play();\r\n\r\n  /// Completely stops playback, clears the current station, and dismisses the notification.\r\n  Future<void> stop() async {\r\n    await _handler.stop();\r\n    _currentStation = null;\r\n    _currentSong = null;\r\n    _currentArtwork = null;\r\n    _isPlaying = false;\r\n    _isBuffering = false;\r\n    _updateTile();\r\n    notifyListeners();\r\n  }",
  );

  file.writeAsStringSync(content);
  print('Done!');
}
