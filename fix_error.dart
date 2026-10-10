import 'dart:io';

void main() {
  final file = File('lib/providers/player_provider.dart');
  var content = file.readAsStringSync();

  content = content.replaceFirst(
    "    _handler.player.playbackEventStream.listen((event) {}, onError: (e) {\r\n      _hasError = true;\r\n      _errorMessage = 'Nie udało się odtworzyć stacji';\r\n      _isPlaying = false;\r\n      _updateTile();\r\n      notifyListeners();\r\n    });",
    "    _handler.player.playbackEventStream.listen((event) {}, onError: (e, stackTrace) {\r\n      _hasError = true;\r\n      String errorDetails = 'Kod błędu: nieznany';\r\n      if (e is PlayerException) {\r\n        errorDetails = 'Błąd [PE-\${e.code}]: \${e.message}';\r\n      } else {\r\n        errorDetails = 'Błąd [SYS]: \${e.toString()}';\r\n      }\r\n      _errorMessage = 'Nie udało się odtworzyć stacji.\\n\$errorDetails';\r\n      _isPlaying = false;\r\n      _updateTile();\r\n      notifyListeners();\r\n    });"
  );

  file.writeAsStringSync(content);
  print('Done!');
}
