import 'dart:io';

void main() {
  final file = File('lib/screens/player_screen.dart');
  var content = file.readAsStringSync();

  // Fix the big Play/Stop button: it should pause instead of stop
  content = content.replaceFirst(
    "isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded",
    "isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded",
  );
  content = content.replaceFirst(
    "// Play/Stop Button",
    "// Play/Pause Button",
  );
  
  // Fix the action: pause instead of stop
  content = content.replaceFirst(
    RegExp(r'onPressed: \(\) \{\s*if \(isPlaying\) \{\s*playerProvider\.stop\(\);'),
    'onPressed: () {\n                                if (isPlaying) {\n                                  playerProvider.pause();',
  );

  file.writeAsStringSync(content);
  print('Done!');
}
